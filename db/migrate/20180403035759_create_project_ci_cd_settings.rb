class CreateProjectCiCdSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:project_ci_cd_settings)
      create_table(:project_ci_cd_settings) do |t|
        t.integer(:project_id, null: false)
        t.boolean(:group_runners_enabled, default: true, null: false)
      end
    end

    disable_statement_timeout

    # This particular INSERT will take between 10 and 20 seconds.
    execute 'INSERT INTO project_ci_cd_settings (project_id) SELECT id FROM projects'

    # We add the index and foreign key separately so the above INSERT statement
    # takes as little time as possible.
    add_concurrent_index(:project_ci_cd_settings, :project_id, unique: true)

    add_foreign_key_with_retry
  end

  def down
    drop_table :project_ci_cd_settings
  end

  def add_foreign_key_with_retry
    if Gitlab::Database.mysql?
      # When using MySQL we don't support online upgrades, thus projects can't
      # be deleted while we are running this migration.
      return add_project_id_foreign_key
    end

    # Between the initial INSERT and the addition of the foreign key some
    # projects may have been removed, leaving orphaned rows in our new settings
    # table.
    loop do
      remove_orphaned_settings

      begin
        add_project_id_foreign_key
        break
      rescue ActiveRecord::InvalidForeignKey
        say 'project_ci_cd_settings contains some orphaned rows, retrying...'
      end
    end
  end

  def add_project_id_foreign_key
    add_concurrent_foreign_key(:project_ci_cd_settings, :projects, column: :project_id)
  end

  def remove_orphaned_settings
    execute <<~SQL
      DELETE FROM project_ci_cd_settings
      WHERE NOT EXISTS (
        SELECT 1
        FROM projects
        WHERE projects.id = project_ci_cd_settings.project_id
      )
    SQL
  end
end
