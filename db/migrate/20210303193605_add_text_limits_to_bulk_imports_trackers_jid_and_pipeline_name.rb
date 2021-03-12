# frozen_string_literal: true

class AddTextLimitsToBulkImportsTrackersJidAndPipelineName < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :bulk_import_trackers, :jid, 255
  end

  def down
    remove_text_limit :bulk_import_trackers, :jid
  end
end
