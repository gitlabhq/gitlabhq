# frozen_string_literal: true

module API
  module Entities
    class ProtectedBranch < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :name, documentation: { type: 'String', example: 'main' }
      expose :push_access_levels, using: Entities::ProtectedRefAccess, documentation: { is_array: true }
      expose :merge_access_levels, using: Entities::ProtectedRefAccess, documentation: { is_array: true }
      expose :allow_force_push, documentation: { type: 'Boolean' }
    end
  end
end

API::Entities::ProtectedBranch.prepend_mod_with('API::Entities::ProtectedBranch')
