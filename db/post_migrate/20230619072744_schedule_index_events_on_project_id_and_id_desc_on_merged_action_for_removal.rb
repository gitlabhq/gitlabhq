# frozen_string_literal: true

class ScheduleIndexEventsOnProjectIdAndIdDescOnMergedActionForRemoval < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_events_on_project_id_and_id_desc_on_merged_action'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/415091

  def up
    prepare_async_index_removal :events, [:project_id, :id], order: { id: :desc },
      where: "action = 7", name: INDEX_NAME
  end

  def down
    unprepare_async_index :events, [:project_id, :id], order: { id: :desc },
      where: "action = 7", name: INDEX_NAME
  end
end
