# frozen_string_literal: true

class AddRequireDpopForManageApiEndpoints < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :namespace_settings, :require_dpop_for_manage_api_endpoints, :boolean, null: false, default: true
  end
end
