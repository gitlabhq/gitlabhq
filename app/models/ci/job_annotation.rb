# frozen_string_literal: true

module Ci
  class JobAnnotation < Ci::ApplicationRecord
    include Ci::Partitionable

    before_validation :set_project_id, on: :create

    include BulkInsertSafe

    self.table_name = :p_ci_job_annotations
    self.primary_key = :id

    belongs_to :job,
      ->(job_annotation) { in_partition(job_annotation) },
      class_name: 'Ci::Build',
      partition_foreign_key: :partition_id,
      inverse_of: :job_annotations

    query_constraints :id, :partition_id
    partitionable scope: :job, partitioned: true

    validates :data, json_schema: { filename: 'ci_job_annotation_data' }
    validates :name, presence: true, length: { maximum: 255 }
    validates :project_id, presence: true, on: :create

    private

    def set_project_id
      self.project_id ||= job&.project_id
    end
  end
end
