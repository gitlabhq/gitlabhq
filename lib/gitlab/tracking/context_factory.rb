# frozen_string_literal: true

module Gitlab
  module Tracking
    # Factory for creating tracking contexts based on user authentication and context requirements.
    class ContextFactory
      # Creates a tracking context suitable for frontend use.
      #
      # For authenticated users, returns a full StandardContext with all fields.
      # For unauthenticated users, returns a FrontendStandardContext with sensitive
      # fields filtered out (instance_version, instance_id, host_name, plan).
      #
      # @param user [User, nil] The current user (nil if unauthenticated)
      # @param namespace [Namespace, nil] The namespace context
      # @param project_id [Integer, nil] The project ID
      # @param extra [Hash] Additional data to include in the context
      # @return [StandardContext, FrontendStandardContext] The appropriate context
      def self.for_frontend(user:, namespace: nil, project_id: nil, **extra)
        standard_context = StandardContext.new(
          user: user,
          namespace: namespace,
          project_id: project_id,
          **extra
        )

        user.present? ? standard_context : FrontendStandardContext.new(standard_context)
      end
    end
  end
end
