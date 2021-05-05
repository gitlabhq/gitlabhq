# frozen_string_literal: true

class AddRemoteTextLimitToImportUrlInImportExportUpload < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_text_limit :import_export_uploads, :remote_import_url, 512
  end

  def down
    remove_text_limit :import_export_uploads, :remote_import_url
  end
end
