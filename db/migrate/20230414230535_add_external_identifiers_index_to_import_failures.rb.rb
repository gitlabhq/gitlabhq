# frozen_string_literal: true

class AddExternalIdentifiersIndexToImportFailures < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_import_failures_on_external_identifiers'

  def up
    add_concurrent_index :import_failures, :external_identifiers, name: INDEX_NAME,
      where: "external_identifiers != '{}'"
  end

  def down
    remove_concurrent_index_by_name :import_failures, INDEX_NAME
  end
end
