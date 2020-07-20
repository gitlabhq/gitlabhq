# frozen_string_literal: true

class AddSecretsToCiBuildsMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :ci_builds_metadata, :secrets, :jsonb, default: {}, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_builds_metadata, :secrets
    end
  end
end
