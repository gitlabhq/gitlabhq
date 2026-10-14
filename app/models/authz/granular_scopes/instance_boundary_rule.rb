# frozen_string_literal: true

module Authz
  module GranularScopes
    # Boundary rule for instance applications, which have no owner. Any
    # namespace may be a boundary; one from another organization fails
    # GranularScope#organization_match. There is no personal namespace.
    class InstanceBoundaryRule
      ALLOWED_ACCESS = [
        GranularScope::Access::USER,
        GranularScope::Access::INSTANCE,
        GranularScope::Access::ALL_MEMBERSHIPS,
        GranularScope::Access::SELECTED_MEMBERSHIPS
      ].freeze

      # @param access [Symbol, String, nil]
      # @return [Boolean]
      def allowed_access?(access)
        ALLOWED_ACCESS.include?(access&.to_sym)
      end

      # @param resource [Group, Project]
      # @return [Boolean]
      def allowed_resource?(_resource)
        true
      end

      # @raise [AccessNotAllowedError]
      def personal_projects_namespace
        raise AccessNotAllowedError
      end
    end
  end
end
