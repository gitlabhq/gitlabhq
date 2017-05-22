# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCheckNamespacePlanToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :application_settings,
                            :check_namespace_plan,
                            :boolean,
                            default: false,
                            allow_null: false
  end

  def down
    remove_column(:application_settings, :check_namespace_plan)
  end
end
