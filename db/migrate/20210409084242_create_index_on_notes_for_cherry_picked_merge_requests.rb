# frozen_string_literal: true

class CreateIndexOnNotesForCherryPickedMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  NAME = 'index_notes_for_cherry_picked_merge_requests'

  disable_ddl_transaction!

  def up
    add_concurrent_index :notes, [:project_id, :commit_id], where: "((noteable_type)::text = 'MergeRequest'::text)", name: NAME
  end

  def down
    remove_concurrent_index_by_name :notes, name: NAME
  end
end
