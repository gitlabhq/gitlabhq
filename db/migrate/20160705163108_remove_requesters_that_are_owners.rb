class RemoveRequestersThatAreOwners < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def up
    # Delete requesters that are owner of their projects and actually requested
    # access to it
    execute <<-SQL
      DELETE FROM members
      WHERE members.source_type = 'Project'
      AND members.type = 'ProjectMember'
      AND members.requested_at IS NOT NULL
      AND members.user_id = (
        SELECT namespaces.owner_id
        FROM namespaces
        JOIN projects ON namespaces.id = projects.namespace_id
        WHERE namespaces.type IS NULL
        AND projects.id = members.source_id
        AND namespaces.owner_id = members.user_id);
    SQL

    # Delete requesters that are owner of their project's group and actually requested
    # access to it
    execute <<-SQL
      DELETE FROM members
      WHERE members.source_type = 'Project'
      AND members.type = 'ProjectMember'
      AND members.requested_at IS NOT NULL
      AND members.user_id = (
        SELECT namespaces.owner_id
        FROM namespaces
        JOIN projects ON namespaces.id = projects.namespace_id
        WHERE namespaces.type = 'Group'
        AND projects.id = members.source_id
        AND namespaces.owner_id = members.user_id);
    SQL
  end

  def down
  end
end
