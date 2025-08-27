# frozen_string_literal: true

class DropMergeRequestDiffDeletionsTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.4'

  def up
    drop_trigger(:merge_request_diffs, :merge_request_diffs_loose_fk_trigger, if_exists: true)
  end

  def down
    # Noop
  end
end
