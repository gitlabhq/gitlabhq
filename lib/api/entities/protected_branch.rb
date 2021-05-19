# frozen_string_literal: true

module API
  module Entities
    class ProtectedBranch < Grape::Entity
      expose :id
      expose :name
      expose :push_access_levels, using: Entities::ProtectedRefAccess
      expose :merge_access_levels, using: Entities::ProtectedRefAccess
      expose :allow_force_push
    end
  end
end

API::Entities::ProtectedBranch.prepend_mod_with('API::Entities::ProtectedBranch')
