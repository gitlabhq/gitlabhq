# frozen_string_literal: true

module Ci
  # This table is used to ensure pipeline iid uniqueness across partitions (within a project scope).
  # Its data is modified only by database triggers. It tracks the pipeline iid when a p_ci_pipelines
  # record is added, deleted, or has its iid updated.
  class PipelineIid < Ci::ApplicationRecord
    self.table_name = 'p_ci_pipeline_iids'

    belongs_to :project

    def readonly?
      true
    end
  end
end
