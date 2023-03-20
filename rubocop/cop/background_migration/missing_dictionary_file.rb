# frozen_string_literal: true

require_relative '../../migration_helpers'

module RuboCop
  module Cop
    module BackgroundMigration
      # Checks the batched background migration has the corresponding dictionary file
      class MissingDictionaryFile < RuboCop::Cop::Base
        include MigrationHelpers

        MSG = "Missing %{file_name}. " \
              "Use the generator 'batched_background_migration' to create dictionary files automatically. " \
              "For more details refer: https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#generator"

        DICTIONARY_DIR = "db/docs/batched_background_migrations"

        def_node_matcher :batched_background_migration_name_node, <<~PATTERN
          `(send nil? :queue_batched_background_migration $_ ...)
        PATTERN

        def_node_matcher :migration_constant_value, <<~PATTERN
          `(casgn nil? %const_name ({sym|str} $_))
        PATTERN

        def on_class(node)
          return unless time_enforced?(node) && in_post_deployment_migration?(node)

          migration_name_node = batched_background_migration_name_node(node)
          return unless migration_name_node

          migration_name = if migration_name_node.const_name.present?
                             migration_constant_value(node, const_name: migration_name_node.const_name.to_sym)
                           else
                             migration_name_node.value
                           end

          return if dictionary_file?(migration_name)

          add_offense(node, message: format(MSG, file_name: dictionary_file_path(migration_name)))
        end

        private

        def dictionary_file?(migration_class_name)
          File.exist?(dictionary_file_path(migration_class_name))
        end

        def dictionary_file_path(migration_class_name)
          File.join(rails_root, DICTIONARY_DIR, "#{migration_class_name.underscore}.yml")
        end

        def rails_root
          @rails_root ||= File.expand_path('../../..', __dir__)
        end
      end
    end
  end
end
