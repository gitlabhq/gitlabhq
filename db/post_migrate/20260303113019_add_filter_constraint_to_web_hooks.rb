# frozen_string_literal: true

class AddFilterConstraintToWebHooks < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_web_hooks_filter_is_hash'

  def up
    add_check_constraint(
      :web_hooks,
      "(jsonb_typeof(filter) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :web_hooks, CONSTRAINT_NAME
  end
end
