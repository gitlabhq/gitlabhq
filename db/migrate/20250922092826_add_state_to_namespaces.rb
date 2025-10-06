# frozen_string_literal: true

class AddStateToNamespaces < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- The new state column is
    # fundamental and needs to be in the namespaces table.
    add_column :namespaces, :state, :smallint
    # rubocop:enable Migration/PreventAddingColumns
  end
end
