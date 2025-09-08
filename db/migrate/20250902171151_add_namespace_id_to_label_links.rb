# frozen_string_literal: true

class AddNamespaceIdToLabelLinks < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :label_links, :namespace_id, :bigint
  end
end
