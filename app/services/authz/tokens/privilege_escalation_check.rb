# frozen_string_literal: true

module Authz
  module Tokens
    class PrivilegeEscalationCheck
      include Gitlab::Utils::StrongMemoize

      def initialize(requested_scopes, authenticating_token)
        @requested_scopes = requested_scopes
        @authenticating_token = authenticating_token
      end

      def execute
        return success unless authenticating_token.try(:granular?)

        requested_scopes.each do |requested_scope|
          next if requested_scope_permitted?(requested_scope)

          return error
        end

        success
      end

      private

      attr_reader :requested_scopes, :authenticating_token

      def token_scopes
        authenticating_token.granular_scopes.to_a
      end
      strong_memoize_attr :token_scopes

      def requested_scope_permitted?(requested_scope)
        return true if Array(requested_scope.permissions).empty?

        required = requested_scope.expanded_permissions
        covered = matching_scopes(requested_scope).flat_map(&:expanded_permissions)
        (required - covered).empty?
      end

      def matching_scopes(requested_scope)
        case requested_scope.access.to_sym
        when ::Authz::GranularScope::Access::USER
          token_scopes.select(&:user?)
        when ::Authz::GranularScope::Access::INSTANCE
          token_scopes.select(&:instance?)
        when ::Authz::GranularScope::Access::ALL_MEMBERSHIPS
          token_scopes.select(&:all_memberships?)
        when ::Authz::GranularScope::Access::PERSONAL_PROJECTS
          token_scopes.select { |s| covers_personal_projects?(s, requested_scope) }
        when ::Authz::GranularScope::Access::SELECTED_MEMBERSHIPS
          ancestor_ids = requested_scope.namespace.self_and_ancestor_ids
          token_scopes.select { |s| covers_selected_memberships?(s, ancestor_ids) }
        else
          []
        end
      end

      def covers_personal_projects?(token_scope, requested_scope)
        token_scope.all_memberships? ||
          (token_scope.personal_projects? && token_scope.namespace_id == requested_scope.namespace_id)
      end

      def covers_selected_memberships?(token_scope, ancestor_ids)
        token_scope.all_memberships? ||
          (token_scope.selected_memberships? && ancestor_ids.include?(token_scope.namespace_id))
      end

      def success
        ::ServiceResponse.success
      end

      def error
        ::ServiceResponse.error(
          message: 'A granular token can only create tokens with equal or lesser permissions.',
          reason: :forbidden
        )
      end
    end
  end
end
