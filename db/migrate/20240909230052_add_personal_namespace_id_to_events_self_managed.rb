# frozen_string_literal: true

class AddPersonalNamespaceIdToEventsSelfManaged < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  def up
    return if Gitlab.com_except_jh?

    return if column_exists?(:events, :personal_namespace_id)

    with_lock_retries(raise_on_exhaustion: true) do
      add_column :events, :personal_namespace_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    end
  end

  def down
    return if Gitlab.com_except_jh?

    return unless column_exists?(:events, :personal_namespace_id)

    with_lock_retries(raise_on_exhaustion: true) do
      remove_column :events, :personal_namespace_id
    end
  end
end
