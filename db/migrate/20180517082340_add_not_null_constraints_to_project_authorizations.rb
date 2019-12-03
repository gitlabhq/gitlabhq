class AddNotNullConstraintsToProjectAuthorizations < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    execute <<~SQL
      ALTER TABLE project_authorizations
        ALTER COLUMN user_id SET NOT NULL,
        ALTER COLUMN project_id SET NOT NULL,
        ALTER COLUMN access_level SET NOT NULL
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE project_authorizations
        ALTER COLUMN user_id DROP NOT NULL,
        ALTER COLUMN project_id DROP NOT NULL,
        ALTER COLUMN access_level DROP NOT NULL
    SQL
  end
end
