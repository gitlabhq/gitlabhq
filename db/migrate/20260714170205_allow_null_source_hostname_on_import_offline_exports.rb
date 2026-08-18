# frozen_string_literal: true

class AllowNullSourceHostnameOnImportOfflineExports < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    change_column_null :import_offline_exports, :source_hostname, true
  end

  def down
    change_column_null :import_offline_exports, :source_hostname, false
  end
end
