class AddFingerprintIndex < ActiveRecord::Migration
  def change
    add_index :keys, :fingerprint
  end
end
