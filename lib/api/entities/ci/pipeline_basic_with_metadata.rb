# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineBasicWithMetadata < PipelineBasic
        expose :name,
          documentation: { type: 'string', example: 'Build pipeline' }
      end
    end
  end
end
