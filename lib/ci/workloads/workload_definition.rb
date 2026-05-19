# frozen_string_literal: true

module Ci
  module Workloads
    # This class knows how to take a minimal set of attributes and construct a valid CI job yaml definition. It may in
    # future be able to construct the definitions for other ways of running a workload (e.g. CI steps)
    class WorkloadDefinition
      DEFAULT_TIMEOUT = 2.hours

      attr_accessor :image,
        :commands,
        :variables,
        :artifacts_paths,
        :timeout,
        :cache,
        :tags,
        :services,
        :suspend_on_success,
        :suspend_on_failure,
        :environment_key

      def initialize
        self.timeout = DEFAULT_TIMEOUT
        @variables = {}
        @commands = []
        @services = []
        yield self if block_given?
      end

      def add_variable(name, value)
        self.variables = variables.merge(name => value)
      end

      # Adds a service to the workload definition.
      #
      # @param service [String, Hash] The service to add. Can be:
      #   - A string with the service image name (e.g., 'docker:dind', 'postgres:13')
      #   - A hash with service configuration (e.g., { name: 'postgres:13', alias: 'db' })
      #
      # @example Add Docker in Docker service
      #   workload.add_service('docker:dind')
      #
      # @example Add service with alias
      #   workload.add_service({ name: 'postgres:13', alias: 'db' })
      def add_service(service)
        services.push(service)
      end

      def to_job_hash
        raise ArgumentError, "image cannot be empty" unless image.present?
        raise ArgumentError, "commands cannot be empty" unless commands.any?

        result = {
          image: image,
          stage: 'build',
          timeout: "#{timeout} seconds",
          variables: variables_without_expand,
          script: commands
        }

        result[:artifacts] = { paths: artifacts_paths } if artifacts_paths.present?
        result[:cache] = cache if cache.present?
        result[:services] = services if services.present?

        result[:tags] = tags if tags.present?

        result
      end

      private

      def variables_without_expand
        # We set expand: false so that there is no way for user inputs (e.g. the goal) to expand out other variables
        variables.transform_values do |v|
          { value: v, expand: false }
        end
      end
    end
  end
end
