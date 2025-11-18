# frozen_string_literal: true

require 'yaml'

module RuboCop
  module Cop
    module Search
      # Cop that prevents checking migration_has_finished? on obsolete or non-existing migrations
      #
      # @example
      #
      #   # bad - obsolete migration
      #   def disable_project_joins_for_blob?
      #     Elastic::DataMigrationService
      #       .migration_has_finished?(:backfill_archived_on_issues)
      #   end
      #
      #   # bad - non-existing migration
      #   def disable_project_joins_for_blob?
      #     Elastic::DataMigrationService
      #       .migration_has_finished?(:non_existing_migration)
      #   end
      #
      #   # good - valid migration
      #   def disable_project_joins_for_blob?
      #     Elastic::DataMigrationService.migration_has_finished?(:valid_migration)
      #   end

      class AvoidCheckingFinishedOnInvalidMigrations < RuboCop::Cop::Base
        MSG_OBSOLETE = 'Migration is obsolete and can not be used with `migration_has_finished?`.'
        MSG_NON_EXISTING = 'Migration does not exist and can not be used with `migration_has_finished?`.'
        MSG_MISSING_IMPLEMENTATION = 'Migration implementation file is missing.'

        DOCS_PATH = 'ee/elastic/docs'
        MIGRATIONS_PATH = 'ee/elastic/migrate'
        MIGRATION_REGEXP = /\A([0-9]+)_([_a-z0-9]*)\.rb\z/

        # @!method migration_has_finished?(node)
        def_node_matcher :migration_has_finished?, <<~PATTERN
          (send
            (const (const {nil? cbase} :Elastic) :DataMigrationService) :migration_has_finished?
              (sym $_))
        PATTERN

        RESTRICT_ON_SEND = %i[migration_has_finished?].freeze

        def on_send(node)
          return unless migrations_available?

          migration_has_finished?(node) do |migration_name|
            check_migration(node, migration_name)
          end
        end

        alias_method :on_csend, :on_send

        private

        def migrations_available?
          Dir.exist?(DOCS_PATH) && Dir.exist?(MIGRATIONS_PATH)
        end

        def check_migration(node, migration_name)
          migration_info = find_migration_info(migration_name)

          if migration_info.nil?
            add_offense(node, message: MSG_NON_EXISTING)
          elsif migration_info[:obsolete]
            add_offense(node, message: MSG_OBSOLETE)
          elsif !migration_file_exists?(migration_name)
            add_offense(node, message: MSG_MISSING_IMPLEMENTATION)
          end
        end

        def find_migration_info(migration_name)
          return @migration_cache[migration_name] if @migration_cache&.key?(migration_name)

          @migration_cache ||= load_migrations
          @migration_cache[migration_name]
        end

        def migration_file_exists?(migration_name)
          migration_files_cache.include?(migration_name)
        end

        def migration_files_cache
          @migration_files_cache ||= load_migration_files
        end

        def load_migration_files
          migration_files = Set.new

          Dir.glob("#{MIGRATIONS_PATH}/*.rb").each do |file|
            filename = File.basename(file, '.rb')
            migration_files.add(::Regexp.last_match(1).to_sym) if filename =~ /\A[0-9]+_(.+)\z/
          end

          migration_files
        end

        def load_migrations
          migrations = {}

          migration_files = Dir.glob("#{DOCS_PATH}/*.yml")

          migration_files.each do |file|
            yaml_content = YAML.safe_load_file(file)
            next unless yaml_content.is_a?(Hash)

            name = yaml_content['name']
            next unless name

            # Convert CamelCase to snake_case to match the symbol format used in code
            snake_case_name = name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                                 .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                                 .downcase
                                 .to_sym

            migrations[snake_case_name] = {
              obsolete: yaml_content['obsolete'] == true,
              version: yaml_content['version'],
              milestone: yaml_content['milestone']
            }
          rescue StandardError => e
            # Skip files that can't be parsed, but log for debugging
            warn "Warning: Could not parse migration documentation file #{file}: #{e.message}"
            next
          end

          migrations
        end
      end
    end
  end
end
