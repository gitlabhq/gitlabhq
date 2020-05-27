# frozen_string_literal: true

class BackfillStatusPagePublishedIncidents < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  class Incident < ActiveRecord::Base
    self.table_name = 'status_page_published_incidents'
  end

  class StatusPageIssue < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'issues'

    scope :published_only, -> do
      joins('INNER JOIN status_page_settings ON status_page_settings.project_id = issues.project_id')
        .where('status_page_settings.enabled = true')
        .where(confidential: false)
    end
  end

  def up
    current_time = Time.current

    StatusPageIssue.published_only.each_batch do |batch|
      incidents = batch.map do |status_page_issue|
        {
          issue_id: status_page_issue.id,
          created_at: current_time,
          updated_at: current_time
        }
      end

      Incident.insert_all(incidents, unique_by: :issue_id)
    end
  end

  def down
    # no op

    # While we expect this table to be empty at the point of
    # the up migration, there is no reliable way to determine
    # whether records were added as a part of the migration
    # or after it has run.
  end
end
