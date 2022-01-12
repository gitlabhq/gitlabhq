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
        variables = pipeline.variables_builder.scoped_variables(self, environment: environment, dependencies: dependencies)

        next variables if pipeline.use_variables_builder_definitions?

        variables.concat(project.predefined_variables)
        variables.concat(pipeline.predefined_variables)
        variables.concat(runner.predefined_variables) if runnable? && runner
        variables.concat(kubernetes_variables)
        variables.concat(deployment_variables(environment: environment))
        variables.concat(yaml_variables)
        variables.concat(user_variables)
        variables.concat(dependency_variables) if dependencies
        variables.concat(secret_instance_variables)
        variables.concat(secret_group_variables(environment: environment))
        variables.concat(secret_project_variables(environment: environment))
        variables.concat(trigger_request.user_variables) if trigger_request
        variables.concat(pipeline.variables)
        variables.concat(pipeline.pipeline_schedule.job_variables) if pipeline.pipeline_schedule

        variables
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

    def user_variables
      pipeline.variables_builder.user_variables(user)
    end

    def kubernetes_variables
      pipeline.variables_builder.kubernetes_variables(self)
    end

    def deployment_variables(environment:)
      pipeline.variables_builder.deployment_variables(job: self, environment: environment)
    end

    def secret_instance_variables
      pipeline.variables_builder.secret_instance_variables(ref: git_ref)
    end

    def secret_group_variables(environment: expanded_environment_name)
      pipeline.variables_builder.secret_group_variables(environment: environment, ref: git_ref)
    end

    def secret_project_variables(environment: expanded_environment_name)
      pipeline.variables_builder.secret_project_variables(environment: environment, ref: git_ref)
    end
  end
end
