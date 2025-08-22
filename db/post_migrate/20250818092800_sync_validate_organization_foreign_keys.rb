# frozen_string_literal: true

class SyncValidateOrganizationForeignKeys < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  TABLE_NAME = :organization_users
  FOREIGN_KEYS = {
    organization_id: :fk_8471abad75,
    user_id: :fk_8d9b20725d
  }

  def up
    FOREIGN_KEYS.each do |column, name|
      validate_foreign_key(TABLE_NAME, column, name: name)
    end
  end

  def down
    # no-op
  end
end
