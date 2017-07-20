class ConvertMaxMirrorDelayToMinutesInApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :mirror_max_delay, 300
    execute 'UPDATE application_settings SET mirror_max_delay = COALESCE(mirror_max_delay, 5) * 60'
  end

  def down
    change_column_default :application_settings, :mirror_max_delay, 5
    execute 'UPDATE application_settings SET mirror_max_delay = COALESCE(mirror_max_delay, 300) / 60'
  end
end
