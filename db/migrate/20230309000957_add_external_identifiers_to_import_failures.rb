# frozen_string_literal: true

class AddExternalIdentifiersToImportFailures < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :import_failures, :external_identifiers, :jsonb, default: {}, null: false
  end
end
