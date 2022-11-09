# frozen_string_literal: true

class ValidateFkMemberNamespaceId < Gitlab::Database::Migration[2.0]
  CONSTRAINT_NAME = 'fk_2f85abf8f1'

  def up
    validate_foreign_key :members, :member_namespace_id, name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
