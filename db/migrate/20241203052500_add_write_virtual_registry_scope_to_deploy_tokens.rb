# frozen_string_literal: true

class AddWriteVirtualRegistryScopeToDeployTokens < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :deploy_tokens, :write_virtual_registry, :boolean, default: false, null: false
  end
end
