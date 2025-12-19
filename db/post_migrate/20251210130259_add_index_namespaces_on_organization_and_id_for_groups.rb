# frozen_string_literal: true

class AddIndexNamespacesOnOrganizationAndIdForGroups < Gitlab::Database::Migration[2.3]
  milestone "18.7"
  disable_ddl_transaction!

  INDEX_NAME = "index_namespaces_on_organization_id_and_id_for_groups"

  def up
    # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/database-team/team-tasks/-/issues/560 (internal only)
    add_concurrent_index :namespaces,
      %i[organization_id id],
      unique: false,
      where: "type = 'Group'",
      name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end
