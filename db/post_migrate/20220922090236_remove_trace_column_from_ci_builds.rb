# frozen_string_literal: true

class RemoveTraceColumnFromCiBuilds < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    remove_column :ci_builds, :trace, :text
  end
end
