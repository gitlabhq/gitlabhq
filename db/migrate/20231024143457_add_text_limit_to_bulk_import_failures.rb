# frozen_string_literal: true

class AddTextLimitToBulkImportFailures < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  def up
    add_text_limit :bulk_import_failures, :source_url, 255
    add_text_limit :bulk_import_failures, :source_title, 255
  end

  def down
    remove_text_limit :bulk_import_failures, :source_url
    remove_text_limit :bulk_import_failures, :source_title
  end
end
