# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module Versionable
        extend ActiveSupport::Concern

        class_methods do
          def register_version(version, metadata = {})
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
