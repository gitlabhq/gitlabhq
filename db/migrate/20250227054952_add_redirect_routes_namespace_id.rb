# frozen_string_literal: true

class AddRedirectRoutesNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :redirect_routes, :namespace_id, :bigint
  end
end
