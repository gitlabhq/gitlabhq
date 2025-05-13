# frozen_string_literal: true

class CreateAsyncClosedIncidentsNamespaceIdClosedAtIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  INDEX_NAME = 'index_closed_incidents_on_namespace_id_closed_at'

  def up
    # To be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/541363
    prepare_async_index :issues, [:namespace_id, :closed_at], where: 'state_id = 2 AND work_item_type_id = 2', name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/510
  end

  def down
    unprepare_async_index :issues, INDEX_NAME
  end
end
