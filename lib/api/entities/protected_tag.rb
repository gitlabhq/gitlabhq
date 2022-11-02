# frozen_string_literal: true

module API
  module Entities
    class ProtectedTag < Grape::Entity
      expose :name, documentation: { type: 'string', example: 'release-1-0' }
      expose :create_access_levels, using: Entities::ProtectedRefAccess
    end
  end
end
