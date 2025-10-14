# frozen_string_literal: true

class CreatePackagesPackageFileStates < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    create_table :packages_package_file_states do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory is at ee/spec/factories/geo/package_file_states.rb
      t.datetime_with_timezone :verification_started_at
      t.datetime_with_timezone :verification_retry_at
      t.datetime_with_timezone :verified_at
      t.bigint :package_file_id, null: false

      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, default: 0, limit: 2

      t.binary :verification_checksum, using: 'verification_checksum::bytea'
      t.text :verification_failure, limit: 255

      t.index :package_file_id, unique: true
      t.index :verification_state, name: 'index_packages_package_file_states_on_verification_state'
      t.index :verified_at,
        where: "(verification_state = 0)",
        order: { verified_at: 'ASC NULLS FIRST' },
        name: 'index_packages_package_file_states_pending_verification'
      t.index :verification_retry_at,
        where: "(verification_state = 3)",
        order: { verification_retry_at: 'ASC NULLS FIRST' },
        name: 'index_packages_package_file_states_failed_verification'
    end
  end
end
