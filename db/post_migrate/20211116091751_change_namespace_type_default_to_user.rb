# frozen_string_literal: true

class ChangeNamespaceTypeDefaultToUser < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      change_column_default :namespaces, :type, 'User'
    end
  end

  def down
    with_lock_retries do
      change_column_default :namespaces, :type, nil
    end
  end
end
