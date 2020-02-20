# frozen_string_literal: true

module API
  module Entities
    class ProtectedBranch < Grape::Entity
      expose :id
      expose :name
      expose :push_access_levels, using: Entities::ProtectedRefAccess
      expose :merge_access_levels, using: Entities::ProtectedRefAccess
    end
  end
end

API::Entities::ProtectedBranch.prepend_if_ee('EE::API::Entities::ProtectedBranch')
