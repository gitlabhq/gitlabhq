# frozen_string_literal: true

class AddOrganizationIdToSnippets < Gitlab::Database::Migration[2.2]
  DEFAULT_ORGANIZATION_ID = 1

  milestone '17.2'

  enable_lock_retries!

  def change
    add_column :snippets, :organization_id, :bigint, default: DEFAULT_ORGANIZATION_ID, null: true
  end
end
