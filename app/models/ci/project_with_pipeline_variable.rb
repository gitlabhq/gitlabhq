# frozen_string_literal: true

# This model stores projects for which any pipeline variables have been set.
# Its purpose is to assist in the migration process of setting pipeline variables.
# The minimum override role is set to `no_one_allowed` for projects that haven't used pipeline variables.

module Ci
  class ProjectWithPipelineVariable < ::ApplicationRecord
    self.table_name = 'projects_with_pipeline_variables'
    self.primary_key = :project_id

    belongs_to :project

    def self.upsert_for_pipeline(pipeline)
      return unless pipeline.variables.any?

      upsert({ project_id: pipeline.project_id }, unique_by: :project_id)
    end
  end
end
