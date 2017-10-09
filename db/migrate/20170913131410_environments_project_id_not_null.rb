# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class EnvironmentsProjectIdNotNull < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_foreign_key_for_mysql

    change_column_null :environments, :project_id, false

    add_foreign_key_for_mysql
  end

  def down
    remove_foreign_key_for_mysql

    change_column_null :environments, :project_id, true

    add_foreign_key_for_mysql
  end

  private

  # Create the foreign key explicitly for MySQL.
  def add_foreign_key_for_mysql
    if Gitlab::Database.mysql? && !foreign_key_exists?(:environments, :projects)
      add_foreign_key :environments, :projects, on_delete: :cascade
    end
  end

  # Drop the foreign key explicitly for MySQL.
  def remove_foreign_key_for_mysql
    if Gitlab::Database.mysql? && foreign_key_exists?(:environments, :projects)
      remove_foreign_key :environments, :projects
    end
  end
end

