# frozen_string_literal: true

class MakeSshSignatureKeyNullable < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    change_column_null :ssh_signatures, :key_id, true
  end
end
