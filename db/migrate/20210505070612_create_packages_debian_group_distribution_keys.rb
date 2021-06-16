# frozen_string_literal: true

class CreatePackagesDebianGroupDistributionKeys < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_DISTRIBUTION = 'idx_pkgs_debian_group_distribution_keys_on_distribution_id'

  disable_ddl_transaction!

  def up
    create_table_with_constraints :packages_debian_group_distribution_keys do |t|
      t.timestamps_with_timezone
      t.references :distribution,
        foreign_key: { to_table: :packages_debian_group_distributions, on_delete: :cascade },
        index: { name: INDEX_DISTRIBUTION },
        null: false

      t.text :encrypted_private_key, null: false
      t.text :encrypted_private_key_iv, null: false
      t.text :encrypted_passphrase, null: false
      t.text :encrypted_passphrase_iv, null: false
      t.text :public_key, null: false
      t.text :fingerprint, null: false

      t.text_limit :public_key, 512.kilobytes
      t.text_limit :fingerprint, 255
    end
  end

  def down
    with_lock_retries do
      drop_table :packages_debian_group_distribution_keys
    end
  end
end
