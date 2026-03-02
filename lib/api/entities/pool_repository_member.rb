# frozen_string_literal: true

module API
  module Entities
    class PoolRepositoryMember < Grape::Entity
      expose :relative_path, documentation: { type: 'String' }
      expose :public, documentation: { type: 'Boolean' }
      expose :is_upstream, documentation: { type: 'Boolean' }
    end
  end
end
