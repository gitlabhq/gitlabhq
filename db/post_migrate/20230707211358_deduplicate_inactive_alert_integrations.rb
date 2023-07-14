# frozen_string_literal: true

class DeduplicateInactiveAlertIntegrations < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class HttpIntegration < MigrationRecord
    self.table_name = 'alert_management_http_integrations'
  end

  # Existing unique index ensures that all active integrations are already unique.
  # Any non-unique records must be inactive by definition, but dups are unlikely.
  # At time of writing, gitlab.com has 0 records in this state.
  # Of the ~1600 integrations, only ~100 are even inactive.
  def up
    duplicated_identifiers.each do |(project_id, endpoint_identifier)|
      find_inactive_integrations(project_id, endpoint_identifier).delete_all
    end
  end

  def down
    # no-op -> unable to identify duplicates retroactively
  end

  private

  def duplicated_identifiers
    HttpIntegration
      .group(:project_id, :endpoint_identifier)
      .having('count(id) > 1')
      .pluck(:project_id, :endpoint_identifier)
  end

  def find_inactive_integrations(project_id, endpoint_identifier)
    HttpIntegration.where(
      project_id: project_id,
      endpoint_identifier: endpoint_identifier,
      active: false
    )
  end
end
