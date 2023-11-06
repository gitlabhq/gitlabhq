# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to remove protected_tag_create_access_levels for groups that do not have project_group_links
    # to the project for the associated protected branch
    class DeleteInvalidProtectedTagCreateAccessLevels < BatchedMigrationJob
      operation_name :delete_invalid_protected_tag_create_access_levels
      scope_to ->(relation) { relation.where.not(group_id: nil) }
      feature_category :source_code_management

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
          .joins('INNER JOIN protected_tags ON protected_tags.id = protected_tag_id')
          .joins(%(
            LEFT OUTER JOIN project_group_links pgl
              ON pgl.group_id = protected_tag_create_access_levels.group_id
              AND pgl.project_id = protected_tags.project_id
          ))
          .where(%(
            pgl.id IS NULL
          )).delete_all
        end
      end
    end
  end
end
