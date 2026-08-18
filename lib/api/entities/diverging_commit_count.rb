# frozen_string_literal: true

module API
  module Entities
    class DivergingCommitCount < Grape::Entity
      expose :behind, documentation: { type: 'Integer', example: 3 }
      expose :ahead, documentation: { type: 'Integer', example: 5 }
    end
  end
end
