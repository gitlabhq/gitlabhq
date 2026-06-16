# frozen_string_literal: true

require 'find'

module Gitlab
  module Graphql
    module Queries
      IMPORT_RE = /^#\s*import "(?<path>[^"]+)"$/m
      CONN_DIRECTIVE = /@connection\(key: "\w+"\)/

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
          print_string("#{indent}#{op.operation_type}")
          print_string(" #{op.name}") if op.name

          # Do these on a temp instance, so that we detect any skipped arguments
          # without actually printing the output to the current buffer
          temp_printer = self.class.new
          op.directives.each { |d| temp_printer.print(d) }
          op.selections.each { |s| temp_printer.print(s) }
          @skipped_arguments |= temp_printer.skipped_arguments
          @printed_arguments |= temp_printer.printed_arguments

          # remove variable definitions only used in skipped (client) fields
          vars = op.variables.reject do |v|
            @skipped_arguments.include?(v.name) && @printed_arguments.exclude?(v.name)
          end

          if vars.any?
            print_string("(")
            vars.each_with_index do |v, i|
              print_variable_definition(v)
              print_string(", ") if i < vars.size - 1
            end
            print_string(")")
          end

          print_directives(op.directives)
          print_selections(op.selections, indent: indent)
        ensure
          @in_operation = false
        end

        def print_field(field, indent: '')
          if skips? &&
              (field.directives.any? { |d| d.name == 'client' || d.name == 'persist' } || field.name == '__persist')
            skipped = self.class.new(false)
            skipped.print(field)
            @skipped_fragments |= skipped.used_fragments
            @skipped_arguments |= skipped.printed_arguments

            return
          end

          super

          @fields_printed += 1 if @in_operation
        end

        def print_fragment_definition(fragment_def, indent: "")
          if skips? && @skipped_fragments.include?(fragment_def.name) && @used_fragments.exclude?(fragment_def.name)
            return
          end

          super
        end

        def skips?
          @skips
        end
      end

      class Definition
        SKIP_INCLUDE_DIRECTIVES = %w[skip include].freeze

        attr_reader :file, :imports

        def initialize(path, fragments)
          @file = path
          @fragments = fragments
          @imports = []
          @errors = []
        end

        def text
          qs = [query] + all_imports.uniq.sort.map { |p| fragment(p).query }
          t = qs.join("\n\n").gsub(/\n\n+/, "\n\n")

          return t unless /(@client)|(persist)/.match?(t)

          doc = ::GraphQL.parse(t)
          printer = ClientFieldRedactor.new
          redacted = doc.dup.to_query_string(printer: printer)

          redacted if printer.fields_printed > 0
        end

        # @skip / @include directives are driven by a Boolean `if` argument and
        # may reference distinct variables. Enumerate every true/false assignment
        # of those variables so the reported complexity is the worst case for
        # any single variable assignment rather than summing mutually-exclusive
        # branches.
        def complexity(schema)
          variable_names = directive_if_variable_names
          assignments = boolean_assignments(variable_names)

          assignments.map { |assignment| complexity_for_assignment(schema, assignment) }.max
        end

        def query
          return @query if defined?(@query)

          # CONN_DIRECTIVEs are purely client-side constructs
          @query = File.read(file).gsub(CONN_DIRECTIVE, '').gsub(IMPORT_RE) do
            path = $~[:path]
            @imports << @fragments.resolve(path, file)

            ''
          end
        rescue Errno::ENOENT
          @errors << FileNotFound.new(file)
          @query = nil
        end

        def all_imports
          return [] if query.nil?

          imports.flat_map { |p| [p] + @fragments.get(p).all_imports }
        end

        def all_errors
          return @errors.to_set if query.nil?

          imports.map { |p| fragment(p).all_errors }.reduce(@errors.to_set) { |a, b| a | b }
        end

        def validate(schema)
          return [:client_query, []] if query.present? && text.nil?

          errs = all_errors.presence || schema.validate(text)

          [:validated, errs]
        rescue ::GraphQL::ParseError => e
          [:validated, [WrappedError.new(e)]]
        end

        private

        def fragment(path)
          @fragments.get(path)
        end

        # Compute complexity for one boolean assignment of @skip / @include
        # variables. Field-level argument lookups still get the historical
        # fake values so resolver_complexity (see BaseResolver) yields the
        # maximum possible cost.
        def complexity_for_assignment(schema, var_assignment)
          query = GraphQL::Query.new(schema, text)

          query.define_singleton_method(:arguments_for) do |ast_node, defn|
            if defn.is_a?(Class) && defn < GraphQL::Schema::Directive
              if_arg = ast_node.arguments.find { |a| a.name == 'if' }
              if_value = case if_arg&.value
                         when GraphQL::Language::Nodes::VariableIdentifier
                           var_assignment[if_arg.value.name]
                         when true, false
                           if_arg.value
                         end
              Struct.new(:if).new(if_value)
            else
              Struct.new(:keyword_arguments).new({ sort: true, search: true })
            end
          end

          GraphQL::Analysis::AST.analyze_query(query, [GraphQL::Analysis::AST::QueryComplexity]).first
        end

        # @return [Array<String>] variable names referenced by @skip / @include `if:` args.
        def directive_if_variable_names
          return [] if text.blank?

          variables = Set.new
          document = ::GraphQL.parse(text)

          visit_directives(document) do |directive|
            next unless SKIP_INCLUDE_DIRECTIVES.include?(directive.name)

            if_arg = directive.arguments.find { |a| a.name == 'if' }
            next unless if_arg&.value.is_a?(::GraphQL::Language::Nodes::VariableIdentifier)

            variables << if_arg.value.name
          end

          variables.to_a
        rescue ::GraphQL::ParseError
          []
        end

        def visit_directives(node, &block)
          node.directives.each(&block) if node.respond_to?(:directives)

          if node.respond_to?(:selections)
            node.selections.each { |child| visit_directives(child, &block) }
          elsif node.respond_to?(:definitions)
            node.definitions.each { |child| visit_directives(child, &block) }
          end
        end

        # @return [Array<Hash>] every 2^N combination of true/false for the given variable names.
        def boolean_assignments(variable_names)
          return [{}] if variable_names.empty?

          variable_names.reduce([{}]) do |acc, name|
            acc.flat_map { |a| [a.merge(name => true), a.merge(name => false)] }
          end
        end
      end

      # TODO: some queries live under app/graphql/queries - we should look there if/when we add fragments there
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/361079
      # for fragments too.
      class Fragments
        HOME_RE = %r{^(~|ee_else_ce)/}
        DOTS_RE = %r{^(\.\./)+}
        DOT_RE = %r{^\./}
        IMPLICIT_ROOT = %r{^app/}

        def initialize(root, dir = 'app/assets/javascripts')
          @root = root
          @store = {}
          @dir = dir
        end

        attr_reader :root, :dir

        def get(frag_path)
          @store[frag_path] ||= Definition.new(frag_path, self)
        end

        def resolve(import_path, current_file)
          parent = Pathname.new(current_file).parent
          frag_path = import_path.gsub(HOME_RE, (root / dir).to_s + '/')
          frag_path = frag_path.gsub(DOT_RE) do
            parent.to_s + '/'
          end
          frag_path = frag_path.gsub(DOTS_RE) do |dots|
            rel_dir(parent, dots.split('/').count)
          end
          frag_path.gsub(IMPLICIT_ROOT) do
            (Rails.root / 'app').to_s + '/'
          end
        end

        private

        def rel_dir(path, n_steps_up)
          while n_steps_up > 0
            path = path.parent
            n_steps_up -= 1
          end

          path.to_s + '/'
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
        find(Rails.root / 'app/assets/javascripts') + find(Rails.root / 'app/graphql/queries')
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

Gitlab::Graphql::Queries.prepend_mod
Gitlab::Graphql::Queries::Fragments.prepend_mod
