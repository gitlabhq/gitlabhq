class AddTfaToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    change_table :application_settings do |t|
      t.boolean :require_two_factor_authentication, default: false
      t.integer :two_factor_grace_period, default: 48
    end
  end
end
