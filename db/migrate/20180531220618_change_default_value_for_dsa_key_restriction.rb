class ChangeDefaultValueForDsaKeyRestriction < ActiveRecord::Migration
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    change_column :application_settings, :dsa_key_restriction, :integer, null: false,
                  default: -1

    execute("UPDATE application_settings SET dsa_key_restriction = -1")
  end

  def down
    change_column :application_settings, :dsa_key_restriction, :integer, null: false,
                  default: 0
  end
end
