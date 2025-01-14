# frozen_string_literal: true

class AddNamespaceIdToIssuableSlas < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :issuable_slas, :namespace_id, :bigint
  end
end
