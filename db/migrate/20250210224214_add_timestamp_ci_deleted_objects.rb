# frozen_string_literal: true

class AddTimestampCiDeletedObjects < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    add_timestamps_with_timezone(:ci_deleted_objects, columns: [:created_at], default: -> { 'NOW()' })
  end

  def down
    remove_timestamps(:ci_deleted_objects, columns: [:created_at])
  end
end
