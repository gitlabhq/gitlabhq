# frozen_string_literal: true

module Ci
  class PipelineVariable < Ci::ApplicationRecord
    include Ci::Partitionable
    include Ci::HasVariable
    include Ci::RawVariable
    include Ci::ProjectsWithVariablesQuery

    ignore_column :value, remove_with: '19.1', remove_after: '2026-05-21' # https://gitlab.com/gitlab-org/gitlab/-/work_items/592747

    before_validation :ensure_project_id

    belongs_to :pipeline,
      ->(pipeline_variable) { in_partition(pipeline_variable) },
      partition_foreign_key: :partition_id,
      inverse_of: :variables

    self.primary_key = :id
    self.table_name = :p_ci_pipeline_variables
    self.sequence_name = :ci_pipeline_variables_id_seq

    query_constraints :id, :partition_id
    partitionable scope: :pipeline, partitioned: true

    validates :key, :pipeline, presence: true
    validates :project_id, presence: true

    # Should not be mutated outside of pipeline creation because it has to stay
    # in sync with data stored in pipeline_artifacts_pipeline_variables.
    def readonly?
      persisted?
    end

    def hook_attrs
      { key: key, value: value }
    end

    private

    def ensure_project_id
      self.project_id ||= pipeline&.project_id
    end
  end
end
