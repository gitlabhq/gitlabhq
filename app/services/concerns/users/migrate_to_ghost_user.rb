# When a user is destroyed, some of their associated records are
# moved to a "Ghost User", to prevent these associated records from
# being destroyed.
#
# For example, all the issues/MRs a user has created are _not_ destroyed
# when the user is destroyed.
module Users::MigrateToGhostUser
  extend ActiveSupport::Concern

  attr_reader :ghost_user

  def move_associated_records_to_ghost_user(user)
    # Block the user before moving records to prevent a data race.
    # For example, if the user creates an issue after `migrate_issues`
    # runs and before the user is destroyed, the destroy will fail with
    # an exception.
    user.block

    user.transaction do
      @ghost_user = User.ghost

      migrate_issues(user)
      migrate_merge_requests(user)
      migrate_notes(user)
      migrate_abuse_reports(user)
    end

    user.reload
  end

  private

  def migrate_issues(user)
    user.issues.update_all(author_id: ghost_user.id)
  end

  def migrate_merge_requests(user)
    user.merge_requests.update_all(author_id: ghost_user.id)
  end

  def migrate_notes(user)
    user.notes.update_all(author_id: ghost_user.id)
  end

  def migrate_abuse_reports(user)
    AbuseReport.where(reporter_id: user.id).update_all(reporter_id: ghost_user.id)
  end
end
