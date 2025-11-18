# frozen_string_literal: true

class ValidateCiRunnerTaggingsOrganizationIdNullConstraint < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  TABLE_NAME = 'ci_runner_taggings'
  PARTITION_PREFIXES = %w[instance_type group_type project_type].freeze
  COLUMN_NAME = :organization_id

  def up
    PARTITION_PREFIXES
      .map { |runner_type| "#{TABLE_NAME}_#{runner_type}" }
      .each do |table_name|
        with_lock_retries do
          # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- false positive, as validate_foreign_key is allowed
          validate_not_null_constraint table_name, COLUMN_NAME, constraint_name: 'check_organization_id_nullness'
          # rubocop:enable Migration/WithLockRetriesDisallowedMethod
        end
      end
  end

  def down
    # no-op
  end
end
