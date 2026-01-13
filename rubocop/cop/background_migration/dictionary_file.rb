# frozen_string_literal: true

require_relative '../../migration_helpers'
require_relative '../../../lib/gitlab/utils/batched_background_migrations_dictionary'

URL_PATTERN = %r{\Ahttps://gitlab\.com/gitlab-org/gitlab/-/merge_requests/\d+\z}

module RuboCop
  module Cop
    module BackgroundMigration
      # Checks the batched background migration has the corresponding dictionary file
      #
      # @example
      #   # bad
      #   # Invalid dictionary file missing required keys:
      #   # ---
      #   # name: :SomethingWrong
      #   # note: :just some note
      #
      #   # good
      #   # Valid dictionary file structure:
      #   # ---
      #   # table_name: <Database table name>
      #   # feature_category:
      #       - <List of feature categories using this table.>
      #   # introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/XXXX
      #   # milestone: '17.5'
      class DictionaryFile < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = {
          invalid_url: "Invalid `%{key}` url for the dictionary: %{filename}. Please use the following format: " \
            "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/XXX",
          invalid_milestone: "Invalid `%{key}` for the dictionary: %{filename}. It must be a string. " \
            "Please ensure it is quoted.",
          missing_key: "Mandatory key '%{key}' is missing from the dictionary: %{filename}. " \
            "Please add with an appropriate value.",
          missing_dictionary: <<-MESSAGE.delete("\n").squeeze(' ').strip,
            Missing %{filename}.
            Use the generator 'batched_background_migration' to create dictionary files automatically.
            For more details refer: https://docs.gitlab.com/development/database/batched_background_migrations/#generate-a-batched-background-migration
          MESSAGE
          missing_finalized_by: <<-FINALIZE_MESSAGE.delete("\n").squeeze(' ').strip
            Missing `finalized_by` attribute in dictionary: %{filename} for migration using `ensure_batched_background_migration_is_finished`.
            Please add the finalized_by attribute with the migration version or no-op the migration.
          FINALIZE_MESSAGE
        }.freeze

        DICTIONARY_DIR = "db/docs/batched_background_migrations"
        TIMESTAMP_REGEX = /\A\d{14}\z/

        # @!method batched_background_migration_name_node(node)
        def_node_matcher :batched_background_migration_name_node, <<~PATTERN
          `(send nil? :queue_batched_background_migration $_ ...)
        PATTERN

        # @!method ensure_batched_background_migration_is_finished_node(node)
        def_node_matcher :ensure_batched_background_migration_is_finished_node, <<~PATTERN
          `(send nil? :ensure_batched_background_migration_is_finished (hash <(pair (sym :job_class_name) $_) ...>))
        PATTERN

        # @!method migration_constant_value(node)
        def_node_matcher :migration_constant_value, <<~PATTERN
          `(casgn nil? %const_name ({sym|str} $_))
        PATTERN

        def on_class(node)
          return unless time_enforced?(node) && in_post_deployment_migration?(node)

          check_queue_migration(node, batched_background_migration_name_node(node))
          check_ensure_migration(node, ensure_batched_background_migration_is_finished_node(node))
        end

        def external_dependency_checksum
          ::Gitlab::Utils::BatchedBackgroundMigrationsDictionary.checksum
        end

        private

        def valid_url?(url)
          url.match?(URL_PATTERN)
        end

        def valid_milestone?(milestone)
          milestone.is_a?(String)
        end

        def dictionary_file?(migration_class_name)
          File.exist?(dictionary_file_path(migration_class_name))
        end

        def dictionary_file_path(migration_class_name)
          File.join(rails_root, DICTIONARY_DIR, "#{migration_class_name.underscore}.yml")
        end

        def validate_dictionary_file(migration_name, node)
          filename = dictionary_file_path(migration_name)
          return [:missing_dictionary, { filename: filename }] unless dictionary_file?(migration_name)

          bbm_dictionary = ::Gitlab::Utils::BatchedBackgroundMigrationsDictionary.new(version(node))

          return [:missing_key, { key: :milestone, filename: filename }] unless bbm_dictionary.milestone.present?

          unless valid_milestone?(bbm_dictionary.milestone)
            return [:invalid_milestone, { key: :milestone, filename: filename }]
          end

          unless bbm_dictionary.introduced_by_url.present?
            return [:missing_key, { key: :introduced_by_url, filename: filename }]
          end

          return if valid_url?(bbm_dictionary.introduced_by_url)

          [:invalid_url, { key: :introduced_by_url, filename: filename }]
        end

        def rails_root
          @rails_root ||= File.expand_path('../../..', __dir__)
        end

        def check_queue_migration(node, migration_name_node)
          return unless migration_name_node

          migration_name = extract_migration_name(node, migration_name_node)
          error_code, msg_params = validate_dictionary_file(migration_name, node)

          add_offense(node, message: format(MSG[error_code], msg_params)) if error_code
        end

        def check_ensure_migration(node, migration_name_node)
          return unless migration_name_node

          migration_name = extract_migration_name(node, migration_name_node)
          dictionary = ::Gitlab::Utils::BatchedBackgroundMigrationsDictionary.entry(migration_name)

          return unless dictionary
          return if dictionary.finalized_by&.match?(TIMESTAMP_REGEX)

          add_offense(node, message: format(MSG[:missing_finalized_by], filename: dictionary_file_path(migration_name)))
        end

        def extract_migration_name(node, migration_name_node)
          if migration_name_node.const_name.present?
            migration_constant_value(node, const_name: migration_name_node.const_name.to_sym)
          else
            migration_name_node.value
          end
        end
      end
    end
  end
end
