# frozen_string_literal: true

class AddSourceToResourceStateEvent < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:resource_state_events, :source_commit)
      add_column :resource_state_events, :source_commit, :text
    end

    add_text_limit :resource_state_events, :source_commit, 40
  end

  def down
    remove_column :resource_state_events, :source_commit
  end
end
