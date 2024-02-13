# frozen_string_literal: true

class AddTextLimitToBulkImportFailuresSubrelationColumn < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  disable_ddl_transaction!

  def up
    add_text_limit :bulk_import_failures, :subrelation, 255
  end

  def down
    remove_text_limit :bulk_import_failures, :subrelation
  end
end
