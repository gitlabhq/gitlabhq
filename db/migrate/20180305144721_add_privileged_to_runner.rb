# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPrivilegedToRunner < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :clusters_applications_runners, :privileged, :boolean, default: true, allow_null: false
  end

  def down
    remove_column :clusters_applications_runners, :privileged
  end
end
