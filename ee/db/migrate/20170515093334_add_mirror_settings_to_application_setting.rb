class AddMirrorSettingsToApplicationSetting < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings,
                            :mirror_max_delay,
                            :integer,
                            default: 5,
                            allow_null: false

    add_column_with_default :application_settings,
                            :mirror_max_capacity,
                            :integer,
                            default: 100,
                            allow_null: false

    add_column_with_default :application_settings,
                            :mirror_capacity_threshold,
                            :integer,
                            default: 50,
                            allow_null: false

    ApplicationSetting.expire
  end

  def down
    remove_column :application_settings, :mirror_max_delay
    remove_column :application_settings, :mirror_max_capacity
    remove_column :application_settings, :mirror_capacity_threshold
  end
end
