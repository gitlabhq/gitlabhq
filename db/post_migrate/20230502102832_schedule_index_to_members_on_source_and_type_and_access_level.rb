# frozen_string_literal: true

class ScheduleIndexToMembersOnSourceAndTypeAndAccessLevel < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_members_on_source_and_type_and_access_level'

  def up
    prepare_async_index :members, %i[source_id source_type type access_level], name: INDEX_NAME
  end

  def down
    unprepare_async_index :members, %i[source_id source_type type access_level], name: INDEX_NAME
  end
end
