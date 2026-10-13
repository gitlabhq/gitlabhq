# frozen_string_literal: true

class IncreaseAffectedRangeLimitOnPmAffectedPackages < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  def up
    add_text_limit :pm_affected_packages, :affected_range, 1024,
      constraint_name: check_constraint_name(:pm_affected_packages, :affected_range, 'max_length_1K')
    remove_text_limit :pm_affected_packages, :affected_range,
      constraint_name: check_constraint_name(:pm_affected_packages, :affected_range, 'max_length')
  end

  def down
    # no-op: once the new limit is in use, rows longer than 512 characters may exist,
    # so re-adding the old constraint could fail validation.
  end
end
