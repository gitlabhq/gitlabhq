# frozen_string_literal: true

module API
  module Entities
    class ProtectedRefAccess < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :access_level, documentation: { type: 'integer', example: 40 }
      expose :access_level_description,
        documentation: { type: 'string', example: 'Maintainers' } do |protected_ref_access|
          protected_ref_access.humanize
        end
    end
  end
end

API::Entities::ProtectedRefAccess.prepend_mod_with('API::Entities::ProtectedRefAccess')
