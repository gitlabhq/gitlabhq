# frozen_string_literal: true

class RemoveIndexOnEventsActionAsync < Gitlab::Database::Migration[2.1]
  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/396830
  def up
    prepare_async_index_removal :events, :action, name: 'index_events_on_action'
  end

  def down
    unprepare_async_index :events, :action, name: 'index_events_on_action'
  end
end
