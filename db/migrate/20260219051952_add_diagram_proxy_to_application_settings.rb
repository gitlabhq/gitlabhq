# frozen_string_literal: true

class AddDiagramProxyToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  def up
    with_lock_retries do
      add_column :application_settings, :diagram_proxy, :jsonb, default: {}, null: false, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :diagram_proxy, if_exists: true
    end
  end
end
