# frozen_string_literal: true

class ValidateIdentitiesUserIdForeignKeySynchronously < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_5373344100'

  milestone '18.9'

  def up
    validate_foreign_key :identities, :user_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
