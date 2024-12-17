# frozen_string_literal: true

class AddNamespaceIdToIssuableSeverities < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :issuable_severities, :namespace_id, :bigint
  end
end
