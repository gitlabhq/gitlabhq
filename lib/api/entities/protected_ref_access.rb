# frozen_string_literal: true

module API
  module Entities
    class ProtectedRefAccess < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :access_level, documentation: { type: 'integer', example: 40 }
      expose :humanize, as: :access_level_description, documentation: { type: 'string', example: 'Maintainers' }
      expose :deploy_key_id, documentation: { type: 'integer', example: 1 },
        if: ->(access) { access.has_attribute?(:deploy_key_id) }
    end
  end
end

API::Entities::ProtectedRefAccess.prepend_mod_with('API::Entities::ProtectedRefAccess')
