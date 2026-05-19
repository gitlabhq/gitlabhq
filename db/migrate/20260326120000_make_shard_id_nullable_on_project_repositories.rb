# frozen_string_literal: true

class MakeShardIdNullableOnProjectRepositories < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  def up
    with_lock_retries do
      change_column_null :project_repositories, :shard_id, true
    end
  end

  def down
    with_lock_retries do
      change_column_null :project_repositories, :shard_id, false
    end
  end
end
