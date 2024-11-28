# frozen_string_literal: true

class AddPersonalNamespaceIdToEvents2 < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  # rubocop:disable Migration/SchemaAdditionMethodsNoPost -- https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165127#note_2092878736
  def up
    return unless Gitlab.com_except_jh?

    return if column_exists?(:events, :personal_namespace_id)

    with_lock_retries(raise_on_exhaustion: true) do
      # Doing DDL in post-deployment migration is discouraged in general,
      # this is done as a workaround to prevent production incidents when
      # changing the schema for very high-traffic table
      add_column :events, :personal_namespace_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    end
  end

  def down
    return unless Gitlab.com_except_jh?

    return unless column_exists?(:events, :personal_namespace_id)

    with_lock_retries(raise_on_exhaustion: true) do
      remove_column :events, :personal_namespace_id
    end
  end
  # rubocop:enable Migration/SchemaAdditionMethodsNoPost
end
