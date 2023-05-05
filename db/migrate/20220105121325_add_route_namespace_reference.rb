# frozen_string_literal: true

class AddRouteNamespaceReference < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :routes, :namespace_id, :bigint unless column_exists?(:routes, :namespace_id)
  end

  def down
    remove_column :routes, :namespace_id if column_exists?(:routes, :namespace_id)
  end
end
