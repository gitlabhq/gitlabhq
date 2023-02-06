# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to nullify `projects.creator_id` column of projects who creator
    # does not exist in `users` table anymore.
    class NullifyCreatorIdColumnOfOrphanedProjects < BatchedMigrationJob
      scope_to ->(relation) do
        relation.where.not(creator_id: nil)
                .joins('LEFT OUTER JOIN users ON users.id = projects.creator_id')
                .where(users: { id: nil })
      end

      operation_name :update_all
      feature_category :projects

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(creator_id: nil)
        end
      end
    end
  end
end
