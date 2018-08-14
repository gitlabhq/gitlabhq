class AddNotNullConstraintsToProjectAuthorizations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    if Gitlab::Database.postgresql?
      # One-pass version for PostgreSQL
      execute <<~SQL
      ALTER TABLE project_authorizations
        ALTER COLUMN user_id SET NOT NULL,
        ALTER COLUMN project_id SET NOT NULL,
        ALTER COLUMN access_level SET NOT NULL
      SQL
    else
      change_column_null :project_authorizations, :user_id, false
      change_column_null :project_authorizations, :project_id, false
      change_column_null :project_authorizations, :access_level, false
    end
  end

  def down
    if Gitlab::Database.postgresql?
      # One-pass version for PostgreSQL
      execute <<~SQL
      ALTER TABLE project_authorizations
        ALTER COLUMN user_id DROP NOT NULL,
        ALTER COLUMN project_id DROP NOT NULL,
        ALTER COLUMN access_level DROP NOT NULL
      SQL
    else
      change_column_null :project_authorizations, :user_id, true
      change_column_null :project_authorizations, :project_id, true
      change_column_null :project_authorizations, :access_level, true
    end
  end
end
