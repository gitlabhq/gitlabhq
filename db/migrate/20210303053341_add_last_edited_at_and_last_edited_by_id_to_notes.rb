# frozen_string_literal: true

class AddLastEditedAtAndLastEditedByIdToNotes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :notes, :last_edited_at, :datetime_with_timezone
    end
  end

  def down
    with_lock_retries do
      remove_column :notes, :last_edited_at
    end
  end
end
