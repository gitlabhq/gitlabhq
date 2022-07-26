# frozen_string_literal: true

class RemoveTokenColumnFromCiBuilds < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    remove_column :ci_builds, :token, :string
  end
end
