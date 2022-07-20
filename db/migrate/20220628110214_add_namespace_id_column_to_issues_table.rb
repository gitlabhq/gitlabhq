# frozen_string_literal: true

class AddNamespaceIdColumnToIssuesTable < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column :issues, :namespace_id, :bigint
  end

  def down
    remove_column :issues, :namespace_id
  end
end
