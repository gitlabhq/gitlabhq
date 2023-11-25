# frozen_string_literal: true

class ChangeFkToMemberRoleOnMembersFromCascadeToNullify < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  FK_NAME = 'fk_member_role_on_members'

  def up
    add_concurrent_foreign_key :members, :member_roles, column: :member_role_id, on_delete: :nullify, name: FK_NAME

    with_lock_retries do
      remove_foreign_key :members, column: :member_role_id
    end
  end

  def down
    add_concurrent_foreign_key :members, :member_roles, column: :member_role_id, on_delete: :cascade

    with_lock_retries do
      remove_foreign_key :members, column: :member_role_id, name: FK_NAME
    end
  end
end
