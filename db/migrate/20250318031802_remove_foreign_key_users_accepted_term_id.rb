# frozen_string_literal: true

class RemoveForeignKeyUsersAcceptedTermId < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    # This index was also missing. I think it's possible that we decided we didn't need this due to not deleting rows
    # from application_setting_terms (and thus no concerns of slow cascading deletes) but still it's the only exception
    # to our foreign key rule in the whole application. Since we really do not want to add new indexes to the users
    # table it seemed safer to just remove the foreign key constraint. If it's just being enforced on INSERT/UPDATE this
    # is no worse than what we have accepted for loose foreign keys anyway.
    with_lock_retries do
      remove_foreign_key_if_exists(:users,
        :application_setting_terms,
        column: :accepted_term_id,
        on_delete: :cascade,
        name: :fk_789cd90b35)
    end
  end

  def down
    add_concurrent_foreign_key :users, :application_setting_terms, column: :accepted_term_id, on_delete: :cascade,
      name: :fk_789cd90b35
  end
end
