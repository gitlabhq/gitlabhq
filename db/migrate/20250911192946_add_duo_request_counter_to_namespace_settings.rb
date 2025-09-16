# frozen_string_literal: true

class AddDuoRequestCounterToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :namespace_settings, :duo_agent_platform_request_count, :integer, default: 0, null: false
  end
end
