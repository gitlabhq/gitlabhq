# frozen_string_literal: true

class AddNamespaceTraversalIdsToIssues < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- part of a larger effort to decompose the issues table, see
    # https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/traversal_ids_on_issues/
    add_column :issues, :namespace_traversal_ids, 'bigint[]', default: [], null: true
    # rubocop:enable Migration/PreventAddingColumns
  end
end
