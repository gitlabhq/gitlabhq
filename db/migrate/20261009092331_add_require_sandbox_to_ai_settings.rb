# frozen_string_literal: true

class AddRequireSandboxToAiSettings < Gitlab::Database::Migration[2.4]
  milestone '19.5'

  def change
    add_column :ai_settings, :require_sandbox, :boolean, default: false, null: false
  end
end
