# frozen_string_literal: true

module RuboCop
  module Cop
    module Search
      # Cop that prevents checking migration_has_finished? on deprecated migrations
      #
      # @example
      #
      #   # bad
      #   def disable_project_joins_for_blob?
      #     Elastic::DataMigrationService
      #       .migration_has_finished?(:backfill_project_permissions_in_blobs_using_permutations)
      #   end
      #
      #   # good
      #   def disable_project_joins_for_blob?
      #     Elastic::DataMigrationService.migration_has_finished?(:backfill_project_permissions_in_blobs)
      #   end

      class AvoidCheckingFinishedOnDeprecatedMigrations < RuboCop::Cop::Base
        MSG = 'Migration is deprecated and can not be used with `migration_has_finished?`.'
        DEPRECATED_MIGRATIONS = [
          :backfill_project_permissions_in_blobs_using_permutations,
          :backfill_archived_on_issues
        ].freeze

        def_node_matcher :deprecated_migration?, <<~PATTERN
          (send
            (const (const {nil? cbase} :Elastic) :DataMigrationService) :migration_has_finished?
              (sym {#{DEPRECATED_MIGRATIONS.map { |m| ":#{m}" }.join(' ')}}))
        PATTERN

        RESTRICT_ON_SEND = %i[migration_has_finished?].freeze

        def on_send(node)
          add_offense(node) if deprecated_migration?(node)
        end
      end
    end
  end
end
