# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module Versionable
        extend ActiveSupport::Concern

        # Semantic version format: MAJOR.MINOR.PATCH (e.g., 1.0.0, 2.1.3)
        VERSION_FORMAT = /\A\d+\.\d+\.\d+\z/

        class_methods do
          def register_version(version, metadata = {})
            unless version.match?(VERSION_FORMAT)
              raise ArgumentError,
                "Invalid version format: #{version}. Expected format: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
            end

            @versions = {} unless defined?(@versions)

            @versions[version] = metadata.freeze
          end

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

        # rubocop:disable Gitlab/ModuleWithInstanceVariables -- used to initialize only, read is from version method
        def initialize_version(version = nil)
          @requested_version = version || self.class.latest_version

          raise ArgumentError, "No versions registered for #{self.class.name}" if self.class.available_versions.empty?

          unless @requested_version.match?(VERSION_FORMAT)
            raise ArgumentError,
              "Invalid version format: #{@requested_version}. Expected format: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
          end

          return if self.class.version_exists?(@requested_version)

          raise ArgumentError, "Version #{@requested_version} not found. " \
            "Available: #{self.class.available_versions.join(', ')}"
        end
        # rubocop:enable Gitlab/ModuleWithInstanceVariables

        def version
          @requested_version
        end

        def description
          version_metadata.fetch(:description) { raise NoMethodError, "Description not defined for version #{version}" }
        end

        def input_schema
          version_metadata.fetch(:input_schema) do
            raise NoMethodError, "Input schema not defined for version #{version}"
          end
        end

        # GraphQL-specific methods (only called when needed by GraphQL tools)
        def graphql_operation
          version_metadata.fetch(:graphql_operation) do
            raise NotImplementedError, "GraphQL operation not defined for version #{version}"
          end
        end

        def operation_name
          version_metadata.fetch(:operation_name) do
            raise NotImplementedError, "operation_name must be defined"
          end
        end
        # GraphQL-specific

        protected

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

        # GraphQL-specific
        def graphql_operation_for_version
          version_metadata[:graphql_operation] || graphql_operation
        end

        def build_variables_for_version
          method_name = "build_variables_#{version_method_suffix}"
          respond_to?(method_name, true) ? send(method_name) : build_variables # rubocop:disable GitlabSecurity/PublicSend -- To map version with corresponding method
        end
        # GraphQL-specific

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
end
