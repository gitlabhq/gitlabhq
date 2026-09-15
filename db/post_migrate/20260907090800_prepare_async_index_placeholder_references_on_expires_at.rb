# frozen_string_literal: true

class PrepareAsyncIndexPlaceholderReferencesOnExpiresAt < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :import_source_user_placeholder_references
  COLUMN_NAME = :expires_at
  INDEX_NAME = :index_import_source_user_placeholder_references_on_expires_at

  # TODO: Index to be created synchronously, tracked in https://gitlab.com/gitlab-org/gitlab/-/issues/576118
  def up
    prepare_async_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end
end
