# frozen_string_literal: true

class RemoveTerraformStateVerificationColumns < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    transaction do
      remove_column :terraform_states, :verification_retry_at, :datetime_with_timezone
      remove_column :terraform_states, :verified_at, :datetime_with_timezone
      remove_column :terraform_states, :verification_retry_count, :integer, limit: 2
      remove_column :terraform_states, :verification_checksum, :binary, using: 'verification_checksum::bytea'
      remove_column :terraform_states, :verification_failure, :text
    end
  end

  def down
    add_column(:terraform_states, :verification_retry_at, :datetime_with_timezone) unless column_exists?(:terraform_states, :verification_retry_at)
    add_column(:terraform_states, :verified_at, :datetime_with_timezone) unless column_exists?(:terraform_states, :verified_at)
    add_column(:terraform_states, :verification_retry_count, :integer, limit: 2) unless column_exists?(:terraform_states, :verification_retry_count)
    add_column(:terraform_states, :verification_checksum, :binary, using: 'verification_checksum::bytea') unless column_exists?(:terraform_states, :verification_checksum)
    add_column(:terraform_states, :verification_failure, :text) unless column_exists?(:terraform_states, :verification_failure)

    add_text_limit :terraform_states, :verification_failure, 255
  end
end
