# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddImpersonationToPersonalAccessTokens < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column_with_default :personal_access_tokens, :impersonation, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :personal_access_tokens, :impersonation
  end
end
