# frozen_string_literal: true

module Authz
  module Tokens
    class AuthorizeGranularScopesService
      include Gitlab::Utils::StrongMemoize

      InvalidInputError = Class.new(StandardError)

      def initialize(boundary:, permissions:, token:)
        @boundary = boundary
        @permissions = Array(permissions).map(&:to_sym)
        @token = token

        validate_inputs!
      end

      def execute
        return success unless should_check_authorization?
        return disabled_error unless feature_enabled?
        return missing_inputs_error unless missing_inputs.empty?

        authorized? ? success : access_denied_error
      end

      private

      attr_reader :boundary, :permissions, :token

      def validate_inputs!
        validate_boundary!
        validate_permissions!
      end

      def validate_boundary!
        return if boundary.nil?
        return if boundary.is_a?(::Authz::Boundary::Base)

        raise InvalidInputError, "Boundary must be an instance of Authz::Boundary::Base, got #{boundary.class.name}"
      end

      def validate_permissions!
        return if permissions.empty?

        invalid_permissions = permissions - Authz::PermissionGroups::Assignable.all_permissions
        return if invalid_permissions.empty?

        raise InvalidInputError, "Invalid permissions: #{invalid_permissions.join(', ')}"
      end

      def should_check_authorization?
        token_supports_granular_permissions? &&
          (token.granular? || granular_token_required?)
      end

      def feature_enabled?
        Feature.enabled?(:granular_personal_access_tokens, token.user)
      end

      def authorized?
        missing_permissions.empty?
      end

      def token_supports_granular_permissions?
        token.respond_to?(:granular?) && token.respond_to?(:can?)
      end

      def granular_token_required?
        false # to be implemented as a namespace setting
      end

      def missing_inputs
        { token:, boundary:, permissions: }.select { |_, value| value.blank? }.keys
      end
      strong_memoize_attr :missing_inputs

      def missing_permissions
        permissions.reject { |permission| token.can?(permission, boundary) }
      end
      strong_memoize_attr :missing_permissions

      def disabled_error
        error 'Granular tokens are not yet supported'
      end

      def missing_inputs_error
        error "Unable to determine #{missing_inputs.to_sentence} for authorization"
      end

      def success
        ::ServiceResponse.success
      end

      def access_denied_error
        error format("Access denied: Your %{token} lacks the required permissions: [%{permissions}]%{path}.",
          token: token.class.name.titleize,
          permissions: missing_permissions.join(', '),
          path: (" for \"#{boundary.path}\"" if boundary.path))
      end

      def error(message)
        ::ServiceResponse.error(message:)
      end
    end
  end
end
