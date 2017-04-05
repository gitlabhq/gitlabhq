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
    # For example, if the user creates an issue after `move_issues_to_ghost_user`
    # runs and before the user is destroyed, the destroy will fail with
    # an exception.
    user.block

    user.transaction do
      @ghost_user = User.ghost

      move_issues_to_ghost_user(user)
      move_merge_requests_to_ghost_user(user)
    end

    user.reload
  end

  private

  def move_issues_to_ghost_user(user)
    user.issues.update_all(author_id: ghost_user.id)
  end

  def move_merge_requests_to_ghost_user(user)
    user.merge_requests.update_all(author_id: ghost_user.id)
  end
end
