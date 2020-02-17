# frozen_string_literal: true

module API
  module Entities
    class ProtectedRefAccess < Grape::Entity
      expose :access_level
      expose :access_level_description do |protected_ref_access|
        protected_ref_access.humanize
      end
    end
  end
end

API::Entities::ProtectedRefAccess.prepend_if_ee('EE::API::Entities::ProtectedRefAccess')
