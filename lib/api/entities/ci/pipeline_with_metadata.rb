# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineWithMetadata < Pipeline
        expose :name,
          documentation: { type: 'string', example: 'Build pipeline' },
          if: ->(pipeline, _) { ::Feature.enabled?(:pipeline_name_in_api, pipeline.project) }
      end
    end
  end
end
