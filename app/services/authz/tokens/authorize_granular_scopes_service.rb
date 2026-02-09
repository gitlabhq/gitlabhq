# frozen_string_literal: true

module Authz
  module Tokens
    class AuthorizeGranularScopesService
      include Gitlab::Utils::StrongMemoize

      InvalidInputError = Class.new(StandardError)

      BOUNDARY_TYPE_ORDER = { project: 0, group: 1, user: 2, instance: 3 }.freeze

      def initialize(boundaries:, permissions:, token:)
        @boundaries = Array(boundaries).compact_blank
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

      attr_reader :boundaries, :permissions, :token

      def validate_inputs!
        validate_boundaries!
        validate_permissions!
      end

      def validate_boundaries!
        return if boundaries.empty?
        return if boundaries.all?(::Authz::Boundary::Base)

        raise InvalidInputError,
          "Boundaries must be instances of Authz::Boundary::Base, got #{boundaries.map(&:class).join(', ')}"
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

      def boundaries_by_priority
        boundaries.sort_by do |b|
          boundary_type = b.is_a?(::Authz::Boundary::NilBoundary) ? b.boundary : b.boundary.class.name.downcase.to_sym
          BOUNDARY_TYPE_ORDER[boundary_type]
        end
      end
      strong_memoize_attr :boundaries_by_priority

      def authorized?
        boundaries_by_priority.any? do |boundary|
          missing_permissions_by_boundary[boundary].empty?
        end
      end

      def token_supports_granular_permissions?
        token.respond_to?(:granular?) && token.respond_to?(:can?)
      end

      def granular_token_required?
        false # to be implemented as a namespace setting
      end

      def missing_inputs
        { token:, boundaries:, permissions: }.select { |_, value| value.blank? }.keys
      end
      strong_memoize_attr :missing_inputs

      def missing_permissions_by_boundary
        boundaries_by_priority.each_with_object({}) do |boundary, memo|
          next memo if memo.values.any?(&:empty?) # short-circuit if token is already authorized on a boundary

          memo[boundary] = permissions.reject do |permission|
            token.can?(permission, boundary)
          end
        end
      end
      strong_memoize_attr :missing_permissions_by_boundary

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
        token_type = token.class.name.titleize
        error "Access denied: Your #{token_type} lacks the required permissions: #{missing_permissions_error}."
      end

      def missing_permissions_error
        missing_permissions_by_boundary.filter_map do |boundary, missing_permissions|
          next if missing_permissions.empty?

          format("[%{permissions}]%{path}",
            permissions: missing_permissions.join(', '),
            path: (" for \"#{boundary.path}\"" if boundary.path)
          )
        end.join(', ')
      end

      def error(message)
        ::ServiceResponse.error(message:)
      end
    end
  end
end
