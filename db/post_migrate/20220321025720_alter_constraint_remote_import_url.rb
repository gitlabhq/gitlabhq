# frozen_string_literal: true

class AlterConstraintRemoteImportUrl < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    remove_text_limit :import_export_uploads, :remote_import_url
    add_text_limit :import_export_uploads, :remote_import_url, 2048
  end

  def down
    # no-op
  end
end
