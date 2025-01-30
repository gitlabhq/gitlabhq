# frozen_string_literal: true

# When a user is destroyed, some of their associated records are
# moved to a "Ghost User", to prevent these associated records from
# being destroyed.
#
# For example, all the issues/MRs a user has created are _not_ destroyed
# when the user is destroyed.
module Users
  class MigrateRecordsToGhostUserService
    extend ActiveSupport::Concern

    DestroyError = Class.new(StandardError)

    attr_reader :ghost_user, :user, :initiator_user, :hard_delete

    def initialize(user, initiator_user, execution_tracker)
      @user = user
      @initiator_user = initiator_user
      @execution_tracker = execution_tracker
      @ghost_user = Users::Internal.ghost
    end

    def execute(hard_delete: false)
      @hard_delete = hard_delete

      migrate_records
      post_migrate_records
    end

    private

    attr_reader :execution_tracker

    def migrate_records
      migrate_user_achievements

      return if hard_delete

      migrate_authored_todos
      migrate_issues
      migrate_merge_requests
      migrate_notes
      migrate_abuse_reports
      migrate_award_emoji
      migrate_snippets
      migrate_reviews
      migrate_releases
    end

    def post_migrate_records
      delete_snippets

      # Rails attempts to load all related records into memory before
      # destroying: https://github.com/rails/rails/issues/22510
      # This ensures we delete records in batches.
      user.destroy_dependent_associations_in_batches(exclude: [:snippets])
      user.nullify_dependent_associations_in_batches

      # Destroy the namespace after destroying the user since certain methods may depend on the namespace existing
      user_data = user.destroy
      user.namespace.destroy

      user_data
    end

    def delete_snippets
      response = Snippets::BulkDestroyService.new(initiator_user, user.snippets).execute(skip_authorization: true)
      raise DestroyError, response.message if response.error?
    end

    def migrate_authored_todos
      batched_migrate(Todo, :author_id)
    end

    def migrate_issues
      batched_migrate(Issue, :author_id)
      batched_migrate(Issue, :last_edited_by_id)
    end

    def migrate_merge_requests
      batched_migrate(MergeRequest, :author_id)
      batched_migrate(MergeRequest, :merge_user_id)
    end

    def migrate_notes
      batched_migrate(Note, :author_id)
    end

    def migrate_abuse_reports
      user.reported_abuse_reports.update_all(reporter_id: ghost_user.id)
    end

    def migrate_award_emoji
      user.award_emoji.update_all(user_id: ghost_user.id)
    end

    def migrate_snippets
      snippets = user.snippets.only_project_snippets
      snippets.update_all(author_id: ghost_user.id)
    end

    def migrate_reviews
      batched_migrate(Review, :author_id)
    end

    def migrate_releases
      batched_migrate(Release, :author_id)
    end

    def migrate_user_achievements
      batched_migrate(Achievements::UserAchievement, :awarded_by_user_id)
      batched_migrate(Achievements::UserAchievement, :revoked_by_user_id)
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def batched_migrate(base_scope, column, batch_size: 50)
      loop do
        update_count = base_scope.where(column => user.id).limit(batch_size).update_all(column => ghost_user.id)
        break if update_count == 0
        raise Gitlab::Utils::ExecutionTracker::ExecutionTimeOutError if execution_tracker.over_limit?
      end
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end

Users::MigrateRecordsToGhostUserService.prepend_mod_with('Users::MigrateRecordsToGhostUserService')
