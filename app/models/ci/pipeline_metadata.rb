# frozen_string_literal: true

module Ci
  class PipelineMetadata < Ci::ApplicationRecord
    self.primary_key = :pipeline_id

    belongs_to :pipeline, class_name: "Ci::Pipeline", inverse_of: :pipeline_metadata
    belongs_to :project, class_name: "Project", inverse_of: :pipeline_metadata

    validates :pipeline, presence: true
    validates :project, presence: true
    validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  end
end
