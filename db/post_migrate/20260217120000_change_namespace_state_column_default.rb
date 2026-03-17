# frozen_string_literal: true

class ChangeNamespaceStateColumnDefault < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    change_column_default :namespaces, :state, from: nil, to: 0
  end
end
