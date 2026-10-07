# frozen_string_literal: true

class DropNotNullConstraintFromPmCheckpointsPurlType < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def up
    change_column_null :pm_checkpoints, :purl_type, true
  end

  def down
    change_column_null :pm_checkpoints, :purl_type, false
  end
end
