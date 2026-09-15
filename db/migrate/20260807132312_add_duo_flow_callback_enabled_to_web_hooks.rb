# frozen_string_literal: true

class AddDuoFlowCallbackEnabledToWebHooks < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :web_hooks, :duo_flow_callback_enabled, :boolean, default: false, null: false
  end
end
