# frozen_string_literal: true

class SystemAccessGroupMicrosoftApplicationsUniqueGroupId < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  # rubocop:disable Migration/AddIndex, Migration/RemoveIndex -- these are on empty tables
  def up
    # these tables are currently unused, there should be no data in them
    # truncating for unexpected cases (local dev, failed migrations, etc)
    truncate_tables! 'system_access_group_microsoft_graph_access_tokens', 'system_access_group_microsoft_applications'

    remove_index :system_access_group_microsoft_applications,
      name: 'index_system_access_group_microsoft_applications_on_group_id'

    add_index :system_access_group_microsoft_applications, :group_id, unique: true
  end

  def down
    remove_index :system_access_group_microsoft_applications,
      name: 'index_system_access_group_microsoft_applications_on_group_id'

    add_index :system_access_group_microsoft_applications, :group_id
  end
  # rubocop:enable Migration/AddIndex, Migration/RemoveIndex
end
