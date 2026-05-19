# frozen_string_literal: true

module API
  module Entities
    class BlameRange < Grape::Entity
      expose :commit, using: ::API::Entities::BlameRangeCommit, documentation: { type: '::API::Entities::BlameRangeCommit' }
      expose :lines, documentation: { type: 'String', is_array: true, example: ['lorem ipsum'] }
    end
  end
end
