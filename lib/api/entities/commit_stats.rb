# frozen_string_literal: true

module API
  module Entities
    class CommitStats < Grape::Entity
      expose :additions, documentation: { type: 'integer', example: 1 }
      expose :deletions, documentation: { type: 'integer', example: 0 }
      expose :total, documentation: { type: 'integer', example: 1 }
    end
  end
end
