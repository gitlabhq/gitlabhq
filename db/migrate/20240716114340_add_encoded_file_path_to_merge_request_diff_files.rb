# frozen_string_literal: true

class AddEncodedFilePathToMergeRequestDiffFiles < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :merge_request_diff_files, :encoded_file_path, :boolean, default: false, null: false
    # rubocop:enable Migration/PreventAddingColumns
  end
end
