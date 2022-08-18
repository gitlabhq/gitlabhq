# frozen_string_literal: true

class AddIdTokenToCiBuildsMetadata < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_builds_metadata, :id_tokens, :jsonb, null: false, default: {}
  end
end
