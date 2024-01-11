# frozen_string_literal: true

module Ci
  class PipelineMetadata < Ci::ApplicationRecord
    include Ci::Partitionable
    include Importable

    self.primary_key = :pipeline_id

    enum auto_cancel_on_new_commit: {
      conservative: 0,
      interruptible: 1,
      none: 2
    }, _prefix: true

    enum auto_cancel_on_job_failure: {
      none: 0,
      all: 1
    }, _prefix: true

    belongs_to :pipeline, class_name: "Ci::Pipeline", inverse_of: :pipeline_metadata
    belongs_to :project, class_name: "Project", inverse_of: :pipeline_metadata

    validates :pipeline, presence: true
    validates :project, presence: true
    validates :name, length: { minimum: 1, maximum: 255 }, allow_nil: true

    partitionable scope: :pipeline
  end
end
