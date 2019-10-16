# frozen_string_literal: true

module Ci
  module Sources
    class Pipeline < ApplicationRecord
      self.table_name = "ci_sources_pipelines"

      belongs_to :project, class_name: "Project"
      belongs_to :pipeline, class_name: "Ci::Pipeline", inverse_of: :source_pipeline

      belongs_to :source_project, class_name: "Project", foreign_key: :source_project_id
      belongs_to :source_job, class_name: "CommitStatus", foreign_key: :source_job_id
      belongs_to :source_pipeline, class_name: "Ci::Pipeline", foreign_key: :source_pipeline_id

      validates :project, presence: true
      validates :pipeline, presence: true

      validates :source_project, presence: true
      validates :source_job, presence: true
      validates :source_pipeline, presence: true
    end
  end
end

::Ci::Sources::Pipeline.prepend_if_ee('::EE::Ci::Sources::Pipeline')
