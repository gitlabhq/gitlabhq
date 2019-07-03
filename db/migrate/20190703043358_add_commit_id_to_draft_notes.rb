# frozen_string_literal: true

class AddCommitIdToDraftNotes < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :draft_notes, :commit_id, :binary
  end
end
