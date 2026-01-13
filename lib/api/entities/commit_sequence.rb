# frozen_string_literal: true

module API
  module Entities
    class CommitSequence < Grape::Entity
      expose :count, documentation: { type: 'Integer', example: 1 }
    end
  end
end
