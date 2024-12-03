# frozen_string_literal: true

class AddNamespaceIdToResourceLinkEvents < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :resource_link_events, :namespace_id, :bigint
  end
end
