# frozen_string_literal: true

class AddIndexOnEventsPersonalNamespaceIdSelfManaged < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  INDEX = 'index_events_on_personal_namespace_id'

  # -- https://gitlab.com/gitlab-org/gitlab/-/issues/462801#note_2081632603
  def up
    return if Gitlab.com_except_jh?

    add_concurrent_index :events, # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
      :personal_namespace_id,
      where: 'personal_namespace_id IS NOT NULL',
      name: INDEX
  end

  def down
    return if Gitlab.com_except_jh?

    remove_concurrent_index_by_name :events, INDEX
  end
end
