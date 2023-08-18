# frozen_string_literal: true

class AddFluxResourceColumnToEnvironments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :environments, :flux_resource_path, :text unless column_exists?(:environments, :flux_resource_path)
    end

    add_text_limit :environments, :flux_resource_path, 255
  end

  def down
    with_lock_retries do
      remove_column :environments, :flux_resource_path, if_exists: true
    end
  end
end
