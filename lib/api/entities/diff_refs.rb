# frozen_string_literal: true

module API
  module Entities
    class DiffRefs < Grape::Entity
      expose :base_sha, documentation: { type: 'String', example: 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
      expose :head_sha, documentation: { type: 'String', example: 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
      expose :start_sha, documentation: { type: 'String', example: 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
    end
  end
end
