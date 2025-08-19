# frozen_string_literal: true

class RemoveNotNullConstraintFromRawMetadata < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    change_column_null(
      :vulnerability_occurrences,
      :raw_metadata,
      true
    )
  end
end
