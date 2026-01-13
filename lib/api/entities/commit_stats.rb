# frozen_string_literal: true

module API
  module Entities
    class CommitStats < Grape::Entity
      expose :additions, documentation: { type: 'Integer', example: 1 }
      expose :deletions, documentation: { type: 'Integer', example: 0 }
      expose :total, documentation: { type: 'Integer', example: 1 }
    end
  end
end
