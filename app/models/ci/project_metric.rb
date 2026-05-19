# frozen_string_literal: true

module Ci
  class ProjectMetric < Ci::ApplicationRecord
    belongs_to :project

    def self.first_pipeline_success_recorded?(project_id)
      where(project_id: project_id).where.not(first_pipeline_succeeded_at: nil).exists?
    end

    def self.record_first_pipeline_success!(project_id, timestamp = Time.current)
      upsert(
        { project_id: project_id, first_pipeline_succeeded_at: timestamp },
        unique_by: :project_id
      )
    end
  end
end
