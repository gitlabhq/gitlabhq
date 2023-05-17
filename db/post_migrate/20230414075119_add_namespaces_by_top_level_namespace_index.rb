# frozen_string_literal: true

class AddNamespacesByTopLevelNamespaceIndex < Gitlab::Database::Migration[2.1]
  def up
    # no-op: re-implemented in AddNamespacesByTopLevelNamespaceIndexV2
  end

  def down
    # no-op
  end
end
