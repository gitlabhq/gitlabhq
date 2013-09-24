class AddFingerprintToKey < ActiveRecord::Migration
  def change
    add_column :keys, :fingerprint, :string
    remove_column :keys, :identifier
  end
end
