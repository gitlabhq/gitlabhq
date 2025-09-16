# frozen_string_literal: true

class PrepareTmpIdxEventsWhereProjectTargetTypeMissing < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  INDEX_NAME = :tmp_idx_events_where_project_target_type_missing
  PROJECT_ACTIONS = [1, 5, 8, 9, 11].freeze # Defined in `/app/models/event.rb`

  def up
    # rubocop:disable Migration/PreventIndexCreation -- temporary index for https://gitlab.com/gitlab-org/gitlab/-/issues/565788
    prepare_async_index(
      :events, :id,
      where: "target_type IS NULL AND action IN (#{PROJECT_ACTIONS.join(',')}) AND project_id IS NOT NULL",
      name: INDEX_NAME
    )
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index_by_name :events, INDEX_NAME
  end
end
