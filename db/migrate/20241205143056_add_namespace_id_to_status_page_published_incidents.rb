# frozen_string_literal: true

class AddNamespaceIdToStatusPagePublishedIncidents < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :status_page_published_incidents, :namespace_id, :bigint
  end
end
