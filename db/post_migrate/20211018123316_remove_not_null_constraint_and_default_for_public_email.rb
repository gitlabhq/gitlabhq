# frozen_string_literal: true

class RemoveNotNullConstraintAndDefaultForPublicEmail < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    change_column_null :users, :public_email, true
    change_column_default :users, :public_email, from: '', to: nil
  end

  def down
    # There may now be nulls in the table, so we cannot re-add the constraint here.
    change_column_default :users, :public_email, from: nil, to: ''
  end
end
