# frozen_string_literal: true

class AddRemoteImportUrlToImportExportUpload < ActiveRecord::Migration[6.0]
  # limit is added in 20210419203018_add_remote_text_limit_to_import_url_in_import_export_upload.rb
  def change
    add_column :import_export_uploads, :remote_import_url, :text # rubocop:disable Migration/AddLimitToTextColumns
  end
end
