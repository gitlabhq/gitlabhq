# When a user is destroyed, some of their associated records are
# moved to a "Ghost User", to prevent these associated records from
# being destroyed.
#
# For example, all the issues/MRs a user has created are _not_ destroyed
# when the user is destroyed.
module Users
  class MigrateToGhostUserService
    extend ActiveSupport::Concern

    attr_reader :ghost_user, :user

    def initialize(user)
      @user = user
    end

    def execute
      # Block the user before moving records to prevent a data race.
      # For example, if the user creates an issue after `migrate_issues`
      # runs and before the user is destroyed, the destroy will fail with
      # an exception.
      user.block

      user.transaction do
        @ghost_user = User.ghost

        migrate_issues
        migrate_merge_requests
        migrate_notes
        migrate_abuse_reports
        migrate_award_emoji
      end

      user.reload
    end

    private

    def migrate_issues
      user.issues.update_all(author_id: ghost_user.id)
    end

    def migrate_merge_requests
      user.merge_requests.update_all(author_id: ghost_user.id)
    end

    def migrate_notes
      user.notes.update_all(author_id: ghost_user.id)
    end

    def migrate_abuse_reports
      user.reported_abuse_reports.update_all(reporter_id: ghost_user.id)
    end

    def migrate_award_emoji
      user.award_emoji.update_all(user_id: ghost_user.id)
    end
  end
end
