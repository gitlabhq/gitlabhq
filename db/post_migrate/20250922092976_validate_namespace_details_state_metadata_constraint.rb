# frozen_string_literal: true

class ValidateNamespaceDetailsStateMetadataConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  TABLE_NAME = :namespace_details
  CONSTRAINT_NAME = 'check_namespace_details_state_metadata_is_hash'

  def up
    validate_check_constraint(TABLE_NAME, CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
