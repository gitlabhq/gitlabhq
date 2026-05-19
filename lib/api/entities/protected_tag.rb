# frozen_string_literal: true

module API
  module Entities
    class ProtectedTag < Grape::Entity
      expose :name, documentation: { type: 'String', example: 'release-1-0' }
      expose :create_access_levels, using: ::API::Entities::ProtectedRefAccess,
        documentation: { type: '::API::Entities::ProtectedRefAccess', is_array: true }
    end
  end
end
