# frozen_string_literal: true

module Authz
  module OauthApplicationGranularScopes
    # Replaces the granular scopes an OAuth application declares. The owner
    # decides which scopes are allowed, so that check lives here rather than
    # in the UI and API that call this service.
    class DeclareService
      include Gitlab::Utils::StrongMemoize

      # @param current_user [User] the actor
      # @param application [Authn::OauthApplication] persisted; saved again to sync its scopes column
      # @param inputs [Array<Hash>] see Authz::GranularScopes::Builder; an empty array clears the set
      # @param access_token [#granular?, nil] the token the actor authenticated with, if any
      def initialize(current_user:, application:, inputs:, access_token: nil)
        @current_user = current_user
        @application = application
        @inputs = inputs
        @access_token = access_token
      end

      def execute
        return error(_('Fine-grained OAuth tokens are disabled.'), :feature_disabled) if feature_disabled?
        return dynamic_application_error if application.dynamic?
        return forbidden_error unless authorized?
        return access_not_allowed_error unless inputs.all? { |input| boundary_rule.allowed_access?(input[:access]) }

        scopes_per_input = inputs.map { |input| GranularScopes::Builder.new([input], boundary_rule: boundary_rule).build }
        # Only a selected_memberships input can yield no scope: the Builder drops IDs that match no record
        return no_resources_error if scopes_per_input.any?(&:empty?)

        scopes = scopes_per_input.flatten

        duplicate = GranularScopes::UniquenessCheck.new(scopes).first_duplicate
        return duplicate_error(duplicate) if duplicate

        escalation_check = Tokens::PrivilegeEscalationCheck.new(scopes, access_token).execute
        return escalation_check if escalation_check.error?

        replace_scopes(scopes)

        ServiceResponse.success(payload: { granular_scopes: scopes, warnings: warnings(scopes) })
      rescue GranularScopes::Builder::ResourceNotAllowedError
        resource_not_allowed_error
      rescue ActiveRecord::RecordInvalid => e
        error(e.record.errors.full_messages.to_sentence, :invalid)
      end

      private

      attr_reader :current_user, :application, :inputs, :access_token

      def feature_disabled?
        Feature.disabled?(:granular_oauth_tokens, current_user)
      end

      def owner
        application.owner
      end

      def authorized?
        Ability.allowed?(current_user, :update_oauth_application_granular_scope, application)
      end

      def boundary_rule
        case owner
        when nil then GranularScopes::InstanceBoundaryRule.new
        when ::Group then GranularScopes::GroupBoundaryRule.new(owner)
        else GranularScopes::ReadBoundaryRule.new(owner)
        end
      end
      strong_memoize_attr :boundary_rule

      def replace_scopes(scopes)
        OauthApplicationGranularScope.transaction do
          scopes.each { |scope| scope.organization_id = application.organization_id }

          # Rails deletes only the join rows of dropped scopes; the AFTER DELETE trigger removes
          # the granular_scopes rows no join table references
          application.granular_scopes = scopes

          # The join rows never touch the application row; its before_validation sync of the
          # granular marker in the scopes column only runs on a save
          application.save!
        end
      end

      def warnings(scopes)
        return [] if scopes.empty? || scopes.any? { |scope| grants_mcp_access?(scope) }

        [s_('OAuthApplication|Tokens cannot use the MCP server without a user-level scope granting execute_mcp_tool.')]
      end

      def grants_mcp_access?(scope)
        scope.user? && scope.expanded_permissions.include?(:execute_mcp_tool)
      end

      def dynamic_application_error
        error(s_('OAuthApplication|Dynamically registered applications cannot declare granular scopes.'),
          :dynamic_application)
      end

      def forbidden_error
        error(s_('OAuthApplication|You are not allowed to declare granular scopes for this application.'), :forbidden)
      end

      def access_not_allowed_error
        error(s_('OAuthApplication|One or more access levels are not allowed for this type of application.'),
          :access_not_allowed)
      end

      def no_resources_error
        error(s_('OAuthApplication|Selected memberships access requires at least one group or project.'),
          :no_resources)
      end

      def resource_not_allowed_error
        error(s_('OAuthApplication|A selected group or project cannot be a boundary for this application.'),
          :resource_not_allowed)
      end

      def duplicate_error(scope)
        message =
          if scope.namespace_id
            s_('OAuthApplication|The application cannot have multiple granular scopes for the same namespace')
          else
            s_('OAuthApplication|The application cannot have multiple granular scopes with the same access level')
          end

        error(message, :duplicate)
      end

      def error(message, reason)
        ServiceResponse.error(message: message, reason: reason)
      end
    end
  end
end
