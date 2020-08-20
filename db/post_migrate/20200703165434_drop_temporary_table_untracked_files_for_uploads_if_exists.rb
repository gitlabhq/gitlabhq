# frozen_string_literal: true

class DropTemporaryTableUntrackedFilesForUploadsIfExists < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute 'DROP TABLE IF EXISTS untracked_files_for_uploads'
  end

  def down
    # no-op - this table should not exist
  end
end
