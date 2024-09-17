# frozen_string_literal: true

class UpdateSbomComponents < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  milestone '17.3'

  class SbomComponent < MigrationRecord
    self.table_name = "sbom_components"
  end

  def up
    # no-op
  end

  def down
    SbomComponent.where.not(organization_id: 1).delete_all
  end
end
