# frozen_string_literal: true

class RemoveSuggestedReviewersBotUserType < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.5'

  def up
    # Remove any existing users with suggested_reviewers_bot user_type
    User.where(user_type: 12).delete_all
  end

  def down
    # This is irreversible as we've deleted the users
    # The enum value 12 for suggested_reviewers_bot can be re-added
    # in the application code if needed
  end
end
