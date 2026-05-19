# frozen_string_literal: true

module API
  module Entities
    class DiffPosition < Grape::Entity
      expose :base_sha, documentation: { type: 'String', example: 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
      expose :start_sha, documentation: { type: 'String', example: 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
      expose :head_sha, documentation: { type: 'String', example: 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
      expose :old_path, documentation: { type: 'String', example: 'files/ruby/popen.rb' }
      expose :new_path, documentation: { type: 'String', example: 'files/ruby/popen.rb' }
      expose :position_type, documentation: { type: 'String', example: 'text' }
    end
  end
end
