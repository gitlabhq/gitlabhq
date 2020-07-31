# frozen_string_literal: true

class MigrateIncidentIssuesToIncidentType < ActiveRecord::Migration[6.0]
  DOWNTIME = false
  BATCH_SIZE = 100

  disable_ddl_transaction!

  LABEL_PROPERTIES = {
    title: 'incident'
  }.freeze

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'

    scope :incident_labelled, -> do
      joins("INNER JOIN label_links ON label_links.target_type = 'Issue' AND label_links.target_id = issues.id")
        .joins("INNER JOIN labels ON labels.id = label_links.label_id")
        .where(labels: LABEL_PROPERTIES)
    end

    enum issue_type: {
      issue: 0,
      incident: 1
    }

    scope :incident_typed, -> { where(issue_type: :incident) }
  end

  def up
    incident_issues = Issue.incident_labelled

    incident_issues.each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(issue_type: :incident)
    end
  end

  def down
    incident_issues = Issue.incident_typed

    incident_issues.each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(issue_type: :issue)
    end
  end
end
