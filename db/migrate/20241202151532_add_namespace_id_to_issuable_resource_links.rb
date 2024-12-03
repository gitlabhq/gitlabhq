# frozen_string_literal: true

class AddNamespaceIdToIssuableResourceLinks < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issuable_resource_links, :namespace_id, :bigint
  end
end
