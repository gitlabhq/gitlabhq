# frozen_string_literal: true

class AddAllDescandantsToNamespaceCache < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :namespace_descendants, :self_and_descendant_ids, 'bigint[]', default: [], null: false
  end
end
