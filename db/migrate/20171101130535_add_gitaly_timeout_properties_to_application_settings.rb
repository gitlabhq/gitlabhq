# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGitalyTimeoutPropertiesToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings,
                            :gitaly_timeout_default,
                            :integer,
                            default: 55
    add_column_with_default :application_settings,
                            :gitaly_timeout_medium,
                            :integer,
                            default: 30
    add_column_with_default :application_settings,
                            :gitaly_timeout_fast,
                            :integer,
                            default: 10
  end

  def down
    remove_column :application_settings, :gitaly_timeout_default
    remove_column :application_settings, :gitaly_timeout_medium
    remove_column :application_settings, :gitaly_timeout_fast
  end
end
