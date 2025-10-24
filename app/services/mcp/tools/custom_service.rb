# frozen_string_literal: true

# rubocop:disable Mcp/UseApiService -- Tool does not depend on REST API
module Mcp
  module Tools
    class CustomService < BaseService
      extend ::Gitlab::Utils::Override

      class << self
        # Register a new version with specific metadata
        def register_version(version, metadata = {})
          @versions = {} unless defined?(@versions)
          @versions[version] = metadata.freeze
        end

        # Get the latest registered version
        def latest_version
          return unless @versions

          @versions.keys.max_by { |v| Gem::Version.new(v) }
        end

        # Get all available versions
        def available_versions
          return [] unless @versions

          @versions.keys.sort_by { |v| Gem::Version.new(v) }
        end

        # Check if a version exists
        def version_exists?(version)
          return false unless @versions

          @versions.key?(version)
        end

        # Get version metadata
        def version_metadata(version)
          return {} unless @versions

          @versions[version] || {}
        end
      end

      attr_reader :requested_version

      def initialize(name:, version: nil)
        super(name: name)
        @requested_version = version || self.class.latest_version

        raise ArgumentError, "No versions registered for #{self.class.name}" if self.class.available_versions.empty?

        return if self.class.version_exists?(@requested_version)

        raise ArgumentError, "Version #{@requested_version} not found. " \
          "Available: #{self.class.available_versions.join(', ')}"
      end

      def version
        @requested_version
      end

      def description
        version_metadata.fetch(:description) { raise NoMethodError, "Description not defined for version #{version}" }
      end

      def input_schema
        version_metadata.fetch(:input_schema) { raise NoMethodError, "Input schema not defined for version #{version}" }
      end

      override :set_cred
      def set_cred(current_user: nil, access_token: nil)
        @current_user = current_user
        _ = access_token # access_token is not used in CustomService
      end

      def execute(request: nil, params: nil)
        return Response.error("#{self.class.name}: current_user is not set") unless current_user.present?

        authorize!(params)

        super
      rescue StandardError => e
        Response.error("Tool execution failed: #{e.message}")
      end

      def authorize!(params)
        target = auth_target(params)
        raise ArgumentError, "#{name}: target object not found, the params received: #{params.inspect}" if target.nil?

        allowed = ::Ability.allowed?(current_user, auth_ability, target)
        return if allowed

        raise Gitlab::Access::AccessDeniedError, "CustomService: User #{current_user.id} does " \
          "not have permission to #{auth_ability} for target #{target.id}"
      end

      def auth_ability
        raise NoMethodError, "#{self.class.name}#auth_ability should be implemented in a subclass"
      end

      def auth_target(_params)
        raise NoMethodError, "#{self.class.name}#auth_target should be implemented in a subclass"
      end

      # rubocop: disable CodeReuse/ActiveRecord -- no need to redefine a scope for the built-in method
      def find_project(project_id)
        raise ArgumentError, "Validation error: project_id must be a string" unless project_id.is_a?(String)

        projects = ::Project.without_deleted.not_hidden
        project =
          if ::API::Helpers::INTEGER_ID_REGEX.match?(project_id)
            projects.find_by(id: project_id)
          elsif project_id.include?('/')
            projects.find_by_full_path(project_id, follow_redirects: true)
          end

        raise StandardError, "Project '#{project_id}' not found or inaccessible" unless project

        project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      protected

      override :perform
      def perform(arguments = {})
        method_name = "perform_#{version_method_suffix}"

        if respond_to?(method_name, true)
          send(method_name, arguments) # rubocop:disable GitlabSecurity/PublicSend -- To map version with corresponding method
        else
          # Fallback to default implementation if version-specific method doesn't exist
          perform_default(arguments)
        end
      end

      # Default implementation - can be overridden in subclasses
      def perform_default(_arguments = {})
        raise NoMethodError, "No implementation found for version #{version}"
      end

      private

      def version_metadata
        self.class.version_metadata(version)
      end

      def version_method_suffix
        version.tr('.', '_')
      end
    end
  end
end
# rubocop:enable Mcp/UseApiService
