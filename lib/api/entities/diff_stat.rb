# frozen_string_literal: true

module API
  module Entities
    class DiffStat < Grape::Entity
      expose :path, documentation: { type: 'String', example: 'app/models/user.rb' }
      expose :old_path, documentation: { type: 'String', example: 'app/models/user.rb' }
      expose :additions, documentation: { type: 'Integer', example: 10 }
      expose :deletions, documentation: { type: 'Integer', example: 3 }
    end
  end
end
