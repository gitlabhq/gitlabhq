# frozen_string_literal: true

module Ci
  module Sources
    class Pipeline < Ci::ApplicationRecord
      include Ci::NamespacedModelName
      include IgnorableColumns

      ignore_columns 'source_job_id_convert_to_bigint', remove_with: '14.5', remove_after: '2021-11-22'

      self.table_name = "ci_sources_pipelines"

      belongs_to :project, class_name: "Project"
      belongs_to :pipeline, class_name: "Ci::Pipeline", inverse_of: :source_pipeline

      belongs_to :source_project, class_name: "Project", foreign_key: :source_project_id
      belongs_to :source_job, class_name: "CommitStatus", foreign_key: :source_job_id
      belongs_to :source_bridge, class_name: "Ci::Bridge", foreign_key: :source_job_id
      belongs_to :source_pipeline, class_name: "Ci::Pipeline", foreign_key: :source_pipeline_id

      validates :project, presence: true
      validates :pipeline, presence: true

      validates :source_project, presence: true
      validates :source_job, presence: true
      validates :source_pipeline, presence: true

      scope :same_project, -> { where(arel_table[:source_project_id].eq(arel_table[:project_id])) }
    end
  end
end
