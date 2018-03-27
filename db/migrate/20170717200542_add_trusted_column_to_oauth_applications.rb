class AddTrustedColumnToOauthApplications < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:oauth_applications, :trusted, :boolean, default: false)
  end

  def down
    remove_column(:oauth_applications, :trusted)
  end
end
