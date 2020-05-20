# frozen_string_literal: true

class AddIndexNonRequestedProjectMembersOnSourceIdSourceType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:members, [:source_id, :source_type], where: "requested_at IS NULL and type = 'ProjectMember'", name: 'index_non_requested_project_members_on_source_id_and_type')
  end

  def down
    remove_concurrent_index_by_name(:members, 'index_non_requested_project_members_on_source_id_and_type')
  end
end
