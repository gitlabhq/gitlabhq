# frozen_string_literal: true

class ValidateOrganizationForeignKeys < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  TABLE_NAME = :organization_users
  FOREIGN_KEYS = {
    organization_id: :fk_8471abad75,
    user_id: :fk_8d9b20725d
  }

  def up
    FOREIGN_KEYS.each do |column, name|
      prepare_async_foreign_key_validation(TABLE_NAME, column, name: name)
    end
  end

  def down
    FOREIGN_KEYS.each do |column, name|
      unprepare_async_foreign_key_validation(TABLE_NAME, column, name: name)
    end
  end
end
