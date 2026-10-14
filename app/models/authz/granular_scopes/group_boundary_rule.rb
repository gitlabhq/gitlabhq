# frozen_string_literal: true

module Authz
  module GranularScopes
    # Boundary rule for group-owned applications. Scopes stay inside the owning
    # group's hierarchy, so instance, all_memberships and personal_projects,
    # which all reach outside it, are refused.
    class GroupBoundaryRule
      ALLOWED_ACCESS = [
        GranularScope::Access::USER,
        GranularScope::Access::SELECTED_MEMBERSHIPS
      ].freeze

      # @param group [Group] the owning group
      def initialize(group)
        @group = group
      end

      # @param access [Symbol, String, nil]
      # @return [Boolean]
      def allowed_access?(access)
        ALLOWED_ACCESS.include?(access&.to_sym)
      end

      # @param resource [Group, Project]
      # @return [Boolean] true for the owning group and any descendant group or project
      def allowed_resource?(resource)
        Boundary.for(resource).namespace.traversal_ids.include?(group.id)
      end

      # @raise [AccessNotAllowedError]
      def personal_projects_namespace
        raise AccessNotAllowedError
      end

      private

      attr_reader :group
    end
  end
end
