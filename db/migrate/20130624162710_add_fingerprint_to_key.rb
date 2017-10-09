# rubocop:disable all
class AddFingerprintToKey < ActiveRecord::Migration[4.2]
  def change
    add_column :keys, :fingerprint, :string
    remove_column :keys, :identifier
  end
end
