class AddFingerprintIndex < ActiveRecord::Migration
  def change
    add_index :keys, :fingerprint, unique: false
  end
end
