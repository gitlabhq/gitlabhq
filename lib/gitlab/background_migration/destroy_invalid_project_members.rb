# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DestroyInvalidProjectMembers < Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) { relation.where(source_type: 'Project') }
      operation_name :delete_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          invalid_project_members = sub_batch
                                      .joins('LEFT OUTER JOIN projects ON members.source_id = projects.id')
                                      .where(projects: { id: nil })
          invalid_ids = invalid_project_members.pluck(:id)

          # the actual delete
          deleted_count = invalid_project_members.delete_all

          Gitlab::AppLogger.info({ message: 'Removing invalid project member records',
                                   deleted_count: deleted_count,
                                   ids: invalid_ids })
        end
      end
    end
  end
end
