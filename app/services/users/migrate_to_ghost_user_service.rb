# frozen_string_literal: true

# When a user is destroyed, some of their associated records are
# moved to a "Ghost User", to prevent these associated records from
# being destroyed.
#
# For example, all the issues/MRs a user has created are _not_ destroyed
# when the user is destroyed.
module Users
  class MigrateToGhostUserService
    extend ActiveSupport::Concern

    attr_reader :ghost_user, :user, :hard_delete

    def initialize(user)
      @user = user
      @ghost_user = User.ghost
    end

    # If an admin attempts to hard delete a user, in some cases associated
    # records may have a NOT NULL constraint on the user ID that prevent that record
    # from being destroyed. In such situations we must assign the record to the ghost user.
    # Passing in `hard_delete: true` will ensure these records get assigned to
    # the ghost user before the user is destroyed. Other associated records will be destroyed.
    # letting the other associated records be destroyed.
    def execute(hard_delete: false)
      @hard_delete = hard_delete
      transition = user.block_transition

      # Block the user before moving records to prevent a data race.
      # For example, if the user creates an issue after `migrate_issues`
      # runs and before the user is destroyed, the destroy will fail with
      # an exception.
      user.block

      begin
        user.transaction do
          migrate_records
        end
      rescue Exception # rubocop:disable Lint/RescueException
        # Reverse the user block if record migration fails
        if transition
          transition.rollback
          user.save!
        end

        raise
      end

      user.reset
    end

    private

    def migrate_records
      return if hard_delete

      migrate_issues
      migrate_merge_requests
      migrate_notes
      migrate_abuse_reports
      migrate_award_emoji
      migrate_snippets
      migrate_reviews
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def migrate_issues
      user.issues.update_all(author_id: ghost_user.id)
      Issue.where(last_edited_by_id: user.id).update_all(last_edited_by_id: ghost_user.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def migrate_merge_requests
      user.merge_requests.update_all(author_id: ghost_user.id)
      MergeRequest.where(merge_user_id: user.id).update_all(merge_user_id: ghost_user.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def migrate_notes
      user.notes.update_all(author_id: ghost_user.id)
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
      user.reviews.update_all(author_id: ghost_user.id)
    end
  end
end

Users::MigrateToGhostUserService.prepend_mod_with('Users::MigrateToGhostUserService')
