# frozen_string_literal: true

class UpdateNamespacesOrganizationId < Gitlab::Database::Migration[2.2]
  class Namespace < MigrationRecord
    self.table_name = 'namespaces'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.6'

  def up
    Namespace.where(organization_id: nil).update_all(
      organization_id: Organizations::Organization::DEFAULT_ORGANIZATION_ID
    )
  end

  def down
    # no-op
  end
end
