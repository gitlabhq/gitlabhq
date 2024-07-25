# frozen_string_literal: true

class AddReadVirtualRegistryToDeployTokens < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :deploy_tokens, :read_virtual_registry, :boolean, default: false, null: false
  end
end
