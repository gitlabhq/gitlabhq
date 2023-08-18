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
                .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/421843')
      end

      operation_name :update_all
      feature_category :groups_and_projects

      def perform
        ::Gitlab::Database.allow_cross_joins_across_databases(url:
          'https://gitlab.com/gitlab-org/gitlab/-/issues/421843') do
          each_sub_batch do |sub_batch|
            sub_batch.update_all(creator_id: nil)
          end
        end
      end
    end
  end
end
