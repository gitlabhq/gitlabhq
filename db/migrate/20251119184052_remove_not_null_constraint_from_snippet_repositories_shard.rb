# frozen_string_literal: true

class RemoveNotNullConstraintFromSnippetRepositoriesShard < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    change_column_null :snippet_repositories, :shard_id, true
  end

  def down
    # No-op
  end
end
