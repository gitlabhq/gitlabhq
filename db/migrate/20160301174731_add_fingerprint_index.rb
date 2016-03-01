class AddFingerprintIndex < ActiveRecord::Migration
  def change
    add_index :keys, :fingerprint, unique: true
  end
end
