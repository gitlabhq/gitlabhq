# frozen_string_literal: true

class RemoveIntegrationsProperties < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def change
    remove_column :integrations, :properties, :text
  end
end
