# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPrivilegedToRunner < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :clusters_applications_runners, :privileged, :boolean, default: true, allow_null: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :clusters_applications_runners, :privileged
  end
end
