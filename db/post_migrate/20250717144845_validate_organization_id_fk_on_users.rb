# frozen_string_literal: true

class ValidateOrganizationIdFkOnUsers < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  FK_NAME = 'fk_d7b9ff90af'

  # foreign key added in 20250709143510_add_foreign_key_to_users_on_organization_id.rb
  def up
    validate_foreign_key(:users, :organization_id, name: FK_NAME)
  end

  def down
    # no-op
  end
end
