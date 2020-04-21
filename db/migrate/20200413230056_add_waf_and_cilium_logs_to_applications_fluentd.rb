# frozen_string_literal: true

class AddWafAndCiliumLogsToApplicationsFluentd < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:clusters_applications_fluentd,
                            :waf_log_enabled,
                            :boolean,
                            default: true,
                            allow_null: false)
    add_column_with_default(:clusters_applications_fluentd,
                            :cilium_log_enabled,
                            :boolean,
                            default: true,
                            allow_null: false)
  end

  def down
    remove_column(:clusters_applications_fluentd,
                  :waf_log_enabled)
    remove_column(:clusters_applications_fluentd,
                  :cilium_log_enabled)
  end
end
