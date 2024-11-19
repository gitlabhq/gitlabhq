# frozen_string_literal: true

class BackfillProjectsOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell
  disable_ddl_transaction!

  class Project < MigrationRecord
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    Project.where(organization_id: nil).each_batch do |projects|
      projects.update_all(organization_id: 1)
    end
  end

  def down
    # no-op
  end
end
