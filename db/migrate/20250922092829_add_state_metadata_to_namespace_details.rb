# frozen_string_literal: true

class AddStateMetadataToNamespaceDetails < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  TABLE = :namespace_details
  COLUMN = :state_metadata
  CONSTRAINT_NAME = 'check_namespace_details_state_metadata_is_hash'

  def up
    add_column TABLE, COLUMN, :jsonb, default: {}, null: false
    add_check_constraint(TABLE, "(jsonb_typeof(#{COLUMN}) = 'object')", CONSTRAINT_NAME, validate: false)
  end

  def down
    remove_check_constraint TABLE, CONSTRAINT_NAME
    remove_column TABLE, COLUMN
  end
end
