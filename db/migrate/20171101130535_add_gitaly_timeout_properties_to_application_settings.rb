# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGitalyTimeoutPropertiesToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings,
               :gitaly_timeout_default,
               :integer,
              default: 55
    add_column :application_settings,
               :gitaly_timeout_fast,
               :integer,
               default: 10
  end
end
