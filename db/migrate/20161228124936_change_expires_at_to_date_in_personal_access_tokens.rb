# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable Migration/Datetime
class ChangeExpiresAtToDateInPersonalAccessTokens < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = true
  DOWNTIME_REASON = 'This migration requires downtime because it alters expires_at column from datetime to date'

  def up
    change_column :personal_access_tokens, :expires_at, :date
  end

  def down
    change_column :personal_access_tokens, :expires_at, :datetime
  end
end
