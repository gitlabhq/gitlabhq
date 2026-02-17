# frozen_string_literal: true

module RuboCop
  module Cop
    module Migration
      # Cop that checks if references to Ai::ActiveContext::Migration files exist.
      #
      # This cop ensures that when code references an ActiveContext migration by class name
      # using `Ai::ActiveContext::Migration.complete?`, the corresponding migration file
      # actually exists in the ee/active_context/migrate directory.
      #
      # @example
      #   # bad (migration file doesn't exist)
      #   Ai::ActiveContext::Migration.complete?('SetCodeIndexingVersions')
      #
      #   # good (migration file exists)
      #   Ai::ActiveContext::Migration.complete?('CreateCode')
      #
      #   # good (using version timestamp)
      #   Ai::ActiveContext::Migration.complete?('20251029093945')
      class ActiveContextMigrationReferenceExists < RuboCop::Cop::Base
        MSG = 'ActiveContext migration `%<class_name>s` does not exist. ' \
          'Ensure the migration file exists in ee/active_context/migrate/ or use a valid version timestamp.'

        VERSION_REGEX = /\A\d{14}\z/
        MIGRATIONS_PATH = 'ee/active_context/migrate'

        # @!method ai_active_context_migration_complete?(node)
        def_node_matcher :ai_active_context_migration_complete?, <<~PATTERN
          (send
            (const
              (const
                (const {nil? (cbase)} :Ai) :ActiveContext
              ) :Migration
            ) :complete?
            $(str _)
            ...
          )
        PATTERN

        def on_send(node)
          check_migration_reference(node)
        end

        alias_method :on_csend, :on_send

        private

        def check_migration_reference(node)
          ai_active_context_migration_complete?(node) do |identifier_node|
            next unless identifier_node&.str_type?

            identifier = identifier_node.value
            next unless identifier.is_a?(String) && !identifier.empty?

            # Skip validation for version timestamps (14-digit numbers)
            next if identifier.match?(VERSION_REGEX)

            # Check if migration file exists for the given class name
            next if migration_exists?(identifier)

            add_offense(identifier_node, message: format(MSG, class_name: identifier))
          end
        rescue StandardError => e
          # Log error but don't crash RuboCop
          warn "Error in ActiveContextMigrationReferenceExists cop: #{e.message}" if ENV['DEBUG']
          warn e.backtrace.first(5).join("\n") if ENV['DEBUG']
        end

        def migration_exists?(class_name)
          return false unless class_name.is_a?(String) && !class_name.empty?

          # Convert CamelCase to snake_case
          snake_case_name = class_name
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .downcase

          # Look for migration file matching the pattern: YYYYMMDDHHMMSS_snake_case_name.rb
          migration_files = Dir.glob(File.join(rails_root, MIGRATIONS_PATH, "*_#{snake_case_name}.rb"))

          migration_files.any?
        rescue StandardError => e
          # If there's an error checking file existence, assume migration doesn't exist
          # This ensures the cop fails safe (reports potential issues rather than hiding them)
          warn "Error checking migration existence for #{class_name}: #{e.message}" if ENV['DEBUG']
          false
        end

        def rails_root
          @rails_root ||= defined?(Rails) && Rails.respond_to?(:root) ? Rails.root.to_s : Dir.pwd
        end
      end
    end
  end
end
