# frozen_string_literal: true

class AddRequireSandboxToNamespaceAiSettings < Gitlab::Database::Migration[2.4]
  milestone '19.5'

  def change
    add_column :namespace_ai_settings, :require_sandbox, :boolean, default: false, null: false
  end
end
