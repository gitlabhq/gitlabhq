# frozen_string_literal: true

class FixInconsistentOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def process_hierarchy(namespace)
    organization_id = namespace['organization_id']
    parent_id = namespace['id']

    execute("
      UPDATE namespaces
      SET organization_id = #{organization_id}
      WHERE parent_id = #{parent_id} AND organization_id != #{organization_id}
    ")
    execute("
      UPDATE projects
      SET organization_id = #{organization_id}
      WHERE namespace_id = #{parent_id}
      AND organization_id != #{organization_id}
    ")

    query = "SELECT id, organization_id, type FROM namespaces WHERE parent_id = #{parent_id}"
    select_all(query).each do |child|
      process_hierarchy(child)
    end
  end

  def up
    query = "SELECT id, organization_id, parent_id FROM namespaces WHERE organization_id > 1 AND parent_id IS NULL"
    select_all(query).each do |namespace|
      process_hierarchy(namespace)
    end
  end

  def down
    # no-op
  end
end
