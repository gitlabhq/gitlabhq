# frozen_string_literal: true

class AddKubernetesNamespaceColumnToEnvironments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :environments, :kubernetes_namespace, :text unless column_exists?(:environments, :kubernetes_namespace)
    end

    add_text_limit :environments, :kubernetes_namespace, 63
  end

  def down
    remove_column :environments, :kubernetes_namespace
  end
end
