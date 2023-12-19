# frozen_string_literal: true

module Ci
  ##
  # This module implements methods that provide context in form of
  # essential CI/CD variables that can be used by a build / bridge job.
  #
  module Contextable
    ##
    # Variables in the environment name scope.
    #
    def scoped_variables(environment: expanded_environment_name, dependencies: true)
      track_duration do
        pipeline
          .variables_builder
          .scoped_variables(self, environment: environment, dependencies: dependencies)
      end
    end

    def unprotected_scoped_variables(
      expose_project_variables:,
      expose_group_variables:,
      environment: expanded_environment_name,
      dependencies: true)

      track_duration do
        pipeline
          .variables_builder
          .unprotected_scoped_variables(
            self,
            expose_project_variables: expose_project_variables,
            expose_group_variables: expose_group_variables,
            environment: environment,
            dependencies: dependencies
          )
      end
    end

    def track_duration
      start_time = ::Gitlab::Metrics::System.monotonic_time
      result = yield
      duration = ::Gitlab::Metrics::System.monotonic_time - start_time

      ::Gitlab::Ci::Pipeline::Metrics
        .pipeline_builder_scoped_variables_histogram
        .observe({}, duration.seconds)

      result
    end

    ##
    # Variables that do not depend on the environment name.
    #
    def simple_variables
      strong_memoize(:simple_variables) do
        scoped_variables(environment: nil)
      end
    end

    def simple_variables_without_dependencies
      strong_memoize(:variables_without_dependencies) do
        scoped_variables(environment: nil, dependencies: false)
      end
    end
  end
end
