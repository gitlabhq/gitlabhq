# frozen_string_literal: true

require 'digest/sha2'
require 'yaml'
require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module Migration
      # Checks for `create_table` calls without a corresponding factory.
      #
      # A factory is looked up two ways, in order:
      # 1. A factory file whose path-derived name ends with the table name.
      # 2. The table's `classes:` from the database dictionary (`db/docs/`)
      #    matched against factory declarations: an explicit `class:` option,
      #    or the class FactoryBot infers from the factory name. This covers
      #    factories whose name differs from the table name, such as
      #    `debian_file_metadatum` for `packages_debian_file_metadata`.
      #
      # This check runs when `ee/` directory is present or when explicitly disabled to avoid false positives for
      # `Lint/RedundantCopDisableDirective`.
      #
      # @example
      #
      #   # bad
      #
      #   create_table :users do |t|
      #     t.string :name
      #     t.timestamps
      #   end
      #   # spec/factories/users.rb does not exist
      #
      # @example
      #
      #   # good
      #
      #   create_table :users do |t|
      #     t.string :name
      #     t.timestamps
      #   end
      #   # spec/factories/users.rb exists
      class EnsureFactoryForTable < RuboCop::Cop::Base
        include CodeReuseHelpers

        MSG = 'No factory found for the table `%{name}`.'

        RESTRICT_ON_SEND = %i[create_table].to_set.freeze
        COP_DISABLE = '#\s*rubocop\s*:\s*(?:disable|todo)\s+.*Migration\s*/\s*EnsureFactoryForTable'
        COP_DISABLE_LINE = /\A(?<line>#{COP_DISABLE}.*)\Z/

        FACTORIES_GLOB = '{,ee/,jh/}spec/factories/**/*.rb'
        DICTIONARY_GLOB = 'db/docs/*.yml'
        FACTORY_DECLARATION = /^\s*factory[\s(]+:(\w+)/
        FACTORY_CLASS_OPTION = /\bclass:\s*(?:['":](?:::)?([A-Z][\w:]*)['"]?|(?:::)?([A-Z][\w:]*))/

        # @!method table_definition(node)
        def_node_matcher :table_definition, <<~PATTERN
          (send nil? RESTRICT_ON_SEND ${(sym $_) (str $_)} ...)
        PATTERN

        def on_send(node)
          # Migrations for EE models don't have factories in CE.
          return if !ee? && disabled_comment_absent?

          table_definition(node) do |table_name_node, table_name|
            unless factory?(table_name.to_s)
              msg = format(MSG, name: table_name)
              add_offense(table_name_node, message: msg)
            end
          end
        end

        def external_dependency_checksum
          self.class.external_dependency_checksum
        end

        private

        def factory?(table_name)
          factory_file_for?(table_name) || factory_declaration_for?(table_name)
        end

        def factory_file_for?(table_name)
          # Partioned tables are prefix with `p_`.
          name = table_name.delete_prefix('p_')
          self.class.factories.any? { |factory| factory.end_with?(name) }
        end

        def factory_declaration_for?(table_name)
          self.class.dictionary_classes(table_name).any? do |klass|
            self.class.factory_classes.include?(klass) ||
              self.class.factory_names.include?(self.class.underscore(klass)) ||
              self.class.factory_inferred_classes.include?(klass)
          end
        end

        def self.factories
          @factories ||= Dir.glob(FACTORIES_GLOB).map do |factory|
            factory.gsub(%r{^(ee/|jh/|)spec/factories/}, '').delete_suffix('.rb').tr('/', '_')
          end
        end

        def self.factory_declarations
          @factory_declarations ||= begin
            names = Set.new
            classes = Set.new

            Dir.glob(FACTORIES_GLOB).each do |path|
              source = File.read(path)
              source.scan(FACTORY_DECLARATION) { |(name)| names << name }
              source.scan(FACTORY_CLASS_OPTION) { |quoted, const| classes << (quoted || const) }
            end

            # `inferred_classes` are the classes FactoryBot infers from factory
            # names, e.g. `factory :abuse_event` -> `AbuseEvent`.
            { names: names, classes: classes, inferred_classes: names.map { |name| camelize(name) }.to_set }
          end
        end

        def self.factory_names
          factory_declarations[:names]
        end

        def self.factory_classes
          factory_declarations[:classes]
        end

        def self.factory_inferred_classes
          factory_declarations[:inferred_classes]
        end

        def self.dictionary_classes(table_name)
          @dictionary_classes ||= {}
          @dictionary_classes.fetch(table_name) do
            path = File.join('db', 'docs', "#{table_name}.yml")
            classes = File.exist?(path) ? Array(YAML.safe_load_file(path)['classes']) : []

            @dictionary_classes[table_name] = classes
          rescue StandardError
            @dictionary_classes[table_name] = []
          end
        end

        def self.camelize(string)
          string.split('_').map(&:capitalize).join
        end

        def self.underscore(string)
          string.gsub('::', '').gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        end

        def self.external_dependency_checksum
          @external_dependency_checksum ||= begin
            root = File.expand_path('../../..', __dir__)
            digest = Digest::SHA256.new
            paths = Dir.glob("#{root}/#{FACTORIES_GLOB}") + Dir.glob("#{root}/#{DICTIONARY_GLOB}")

            paths.sort.each do |path|
              digest.update(path)
              digest.file(path)
            end

            digest.hexdigest
          end
        end

        def disabled_comment_absent?
          processed_source.comments.none? { |comment| COP_DISABLE_LINE.match?(comment.text) }
        end
      end
    end
  end
end
