# frozen_string_literal: true

module Authz
  module GranularScopes
    # Boundary rule for user-owned scopes, such as personal and impersonation
    # tokens: the owner must be able to use the resource as a token boundary.
    class ReadBoundaryRule
      def initialize(user)
        @user = user
      end

      # @param resource [Group, Project]
      # @return [Boolean]
      def allowed_resource?(resource)
        Ability.allowed?(user, :read_boundary, resource)
      end

      # @return [Namespaces::UserNamespace]
      def personal_projects_namespace
        user.namespace
      end

      private

      attr_reader :user
    end
  end
end
