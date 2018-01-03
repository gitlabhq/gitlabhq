class FillMissingUuidOnApplicationSettings < ActiveRecord::Migration
  DOWNTIME = false

  def up
    execute("UPDATE application_settings SET uuid = #{quote(SecureRandom.uuid)} WHERE uuid is NULL")
  end

  def down
  end
end
