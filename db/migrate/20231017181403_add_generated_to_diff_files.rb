# frozen_string_literal: true

class AddGeneratedToDiffFiles < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :merge_request_diff_files, :generated, :boolean # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end
end
