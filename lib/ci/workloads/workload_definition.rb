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
        :timeout

      def initialize
        self.timeout = DEFAULT_TIMEOUT
        @variables = {}
        @commands = []
        yield self if block_given?
      end

      def add_variable(name, value)
        self.variables = variables.merge(name => value)
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
