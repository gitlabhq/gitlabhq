# frozen_string_literal: true

class AddTextLimitToBulkImportsSourceVersion < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :bulk_imports, :source_version, 63
  end

  def down
    remove_text_limit :bulk_imports, :source_version
  end
end
