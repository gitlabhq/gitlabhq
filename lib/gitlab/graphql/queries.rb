# frozen_string_literal: true

require 'find'

module Gitlab
  module Graphql
    module Queries
      IMPORT_RE = /^#\s*import "(?<path>[^"]+)"$/m.freeze
      EE_ELSE_CE = /^ee_else_ce/.freeze
      HOME_RE = /^~/.freeze
      HOME_EE = %r{^ee/}.freeze
      DOTS_RE = %r{^(\.\./)+}.freeze
      DOT_RE = %r{^\./}.freeze
      IMPLICIT_ROOT = %r{^app/}.freeze
      CONN_DIRECTIVE = /@connection\(key: "\w+"\)/.freeze

      class WrappedError
        delegate :message, to: :@error

        def initialize(error)
          @error = error
        end

        def path
          []
        end
      end

      class FileNotFound
        def initialize(file)
          @file = file
        end

        def message
          "File not found: #{@file}"
        end

        def path
          []
        end
      end

      # We need to re-write queries to remove all @client fields. Ideally we
      # would do that as a source-to-source transformation of the AST, but doing it using a
      # printer is much simpler.
      class ClientFieldRedactor < GraphQL::Language::Printer
        attr_reader :fields_printed, :skipped_arguments, :printed_arguments, :used_fragments

        def initialize(skips = true)
          @skips = skips
          @fields_printed = 0
          @in_operation = false
          @skipped_arguments = [].to_set
          @printed_arguments = [].to_set
          @used_fragments = [].to_set
          @skipped_fragments = [].to_set
          @used_fragments = [].to_set
        end

        def print_variable_identifier(variable_identifier)
          @printed_arguments << variable_identifier.name
          super
        end

        def print_fragment_spread(fragment_spread, indent: "")
          @used_fragments << fragment_spread.name
          super
        end

        def print_operation_definition(op, indent: "")
          @in_operation = true
          out = +"#{indent}#{op.operation_type}"
          out << " #{op.name}" if op.name

          # Do these first, so that we detect any skipped arguments
          dirs = print_directives(op.directives)
          sels = print_selections(op.selections, indent: indent)

          # remove variable definitions only used in skipped (client) fields
          vars = op.variables.reject do |v|
            @skipped_arguments.include?(v.name) && !@printed_arguments.include?(v.name)
          end

          if vars.any?
            out << "(#{vars.map { |v| print_variable_definition(v) }.join(", ")})"
          end

          out + dirs + sels
        ensure
          @in_operation = false
        end

        def print_field(field, indent: '')
          if skips? && field.directives.any? { |d| d.name == 'client' }
            skipped = self.class.new(false)

            skipped.print_node(field)
            @skipped_fragments |= skipped.used_fragments
            @skipped_arguments |= skipped.printed_arguments

            return ''
          end

          ret = super

          @fields_printed += 1 if @in_operation && ret != ''

          ret
        end

        def print_fragment_definition(fragment_def, indent: "")
          if skips? && @skipped_fragments.include?(fragment_def.name) && !@used_fragments.include?(fragment_def.name)
            return ''
          end

          super
        end

        def skips?
          @skips
        end
      end

      class Definition
        attr_reader :file, :imports

        def initialize(path, fragments)
          @file = path
          @fragments = fragments
          @imports = []
          @errors = []
          @ee_else_ce = []
        end

        def text(mode: :ce)
          qs = [query] + all_imports(mode: mode).uniq.sort.map { |p| fragment(p).query }
          t = qs.join("\n\n").gsub(/\n\n+/, "\n\n")

          return t unless /@client/.match?(t)

          doc = ::GraphQL.parse(t)
          printer = ClientFieldRedactor.new
          redacted = doc.dup.to_query_string(printer: printer)

          return redacted if printer.fields_printed > 0
        end

        def complexity(schema)
          # See BaseResolver::resolver_complexity
          # we want to see the max possible complexity.
          fake_args = Struct
            .new(:if, :keyword_arguments)
            .new(nil, { sort: true, search: true })

          query = GraphQL::Query.new(schema, text)
          # We have no arguments, so fake them.
          query.define_singleton_method(:arguments_for) { |_x, _y| fake_args }

          GraphQL::Analysis::AST.analyze_query(query, [GraphQL::Analysis::AST::QueryComplexity]).first
        end

        def query
          return @query if defined?(@query)

          # CONN_DIRECTIVEs are purely client-side constructs
          @query = File.read(file).gsub(CONN_DIRECTIVE, '').gsub(IMPORT_RE) do
            path = $~[:path]

            if EE_ELSE_CE.match?(path)
              @ee_else_ce << path.gsub(EE_ELSE_CE, '')
            else
              @imports << fragment_path(path)
            end

            ''
          end
        rescue Errno::ENOENT
          @errors << FileNotFound.new(file)
          @query = nil
        end

        def all_imports(mode: :ce)
          return [] if query.nil?

          home = mode == :ee ? @fragments.home_ee : @fragments.home
          eithers = @ee_else_ce.map { |p| home + p }

          (imports + eithers).flat_map { |p| [p] + @fragments.get(p).all_imports(mode: mode) }
        end

        def all_errors
          return @errors.to_set if query.nil?

          paths = imports + @ee_else_ce.flat_map { |p| [@fragments.home + p, @fragments.home_ee + p] }

          paths.map { |p| fragment(p).all_errors }.reduce(@errors.to_set) { |a, b| a | b }
        end

        def validate(schema)
          return [:client_query, []] if query.present? && text.nil?

          errs = all_errors.presence || schema.validate(text)
          if @ee_else_ce.present?
            errs += schema.validate(text(mode: :ee))
          end

          [:validated, errs]
        rescue ::GraphQL::ParseError => e
          [:validated, [WrappedError.new(e)]]
        end

        private

        def fragment(path)
          @fragments.get(path)
        end

        def fragment_path(import_path)
          frag_path = import_path.gsub(HOME_RE, @fragments.home)
          frag_path = frag_path.gsub(HOME_EE, @fragments.home_ee + '/')
          frag_path = frag_path.gsub(DOT_RE) do
            Pathname.new(file).parent.to_s + '/'
          end
          frag_path = frag_path.gsub(DOTS_RE) do |dots|
            rel_dir(dots.split('/').count)
          end
          frag_path.gsub(IMPLICIT_ROOT) do
            (Rails.root / 'app').to_s + '/'
          end
        end

        def rel_dir(n_steps_up)
          path = Pathname.new(file).parent
          while n_steps_up > 0
            path = path.parent
            n_steps_up -= 1
          end

          path.to_s + '/'
        end
      end

      class Fragments
        def initialize(root, dir = 'app/assets/javascripts')
          @root = root
          @store = {}
          @dir = dir
        end

        def home
          @home ||= (@root / @dir).to_s
        end

        def home_ee
          @home_ee ||= (@root / 'ee' / @dir).to_s
        end

        def get(frag_path)
          @store[frag_path] ||= Definition.new(frag_path, self)
        end
      end

      def self.find(root)
        definitions = []

        ::Find.find(root.to_s) do |path|
          definitions << Definition.new(path, fragments) if query_for_gitlab_schema?(path)
        end

        definitions
      rescue Errno::ENOENT
        [] # root does not exist
      end

      def self.fragments
        @fragments ||= Fragments.new(Rails.root)
      end

      def self.all
        ['.', 'ee'].flat_map do |prefix|
          find(Rails.root / prefix / 'app/assets/javascripts')
        end
      end

      def self.known_failure?(path)
        @known_failures ||= YAML.safe_load(File.read(Rails.root.join('config', 'known_invalid_graphql_queries.yml')))

        @known_failures.fetch('filenames', []).any? { |known_failure| path.to_s.ends_with?(known_failure) }
      end

      def self.query_for_gitlab_schema?(path)
        path.ends_with?('.graphql') &&
          !path.ends_with?('.fragment.graphql') &&
          !path.ends_with?('typedefs.graphql') &&
          !/.*\.customer\.(query|mutation)\.graphql$/.match?(path)
      end
    end
  end
end
