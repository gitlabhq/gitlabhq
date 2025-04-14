# frozen_string_literal: true

class RemoveTopicsOrganizationIdDefault < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  TABLE_NAME = :topics
  COLUMN_NAME = :organization_id
  DEFAULT_ORGANIZATION_ID = 1

  def up
    change_column_default(TABLE_NAME, COLUMN_NAME, nil)
  end

  def down
    change_column_default(TABLE_NAME, COLUMN_NAME, DEFAULT_ORGANIZATION_ID)
  end
end
