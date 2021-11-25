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
      Gitlab::Ci::Variables::Collection.new.tap do |variables|
        break variables if user.blank?

        variables.append(key: 'GITLAB_USER_ID', value: user.id.to_s)
        variables.append(key: 'GITLAB_USER_EMAIL', value: user.email)
        variables.append(key: 'GITLAB_USER_LOGIN', value: user.username)
        variables.append(key: 'GITLAB_USER_NAME', value: user.name)
      end
    end

    def kubernetes_variables
      ::Gitlab::Ci::Variables::Collection.new.tap do |collection|
        # Should get merged with the cluster kubeconfig in deployment_variables, see
        # https://gitlab.com/gitlab-org/gitlab/-/issues/335089
        template = ::Ci::GenerateKubeconfigService.new(self).execute

        if template.valid?
          collection.append(key: 'KUBECONFIG', value: template.to_yaml, public: false, file: true)
        end
      end
    end

    def deployment_variables(environment:)
      return [] unless environment

      project.deployment_variables(
        environment: environment,
        kubernetes_namespace: expanded_kubernetes_namespace
      )
    end

    def secret_instance_variables
      project.ci_instance_variables_for(ref: git_ref)
    end

    def secret_group_variables(environment: expanded_environment_name)
      return [] unless project.group

      project.group.ci_variables_for(git_ref, project, environment: environment)
    end

    def secret_project_variables(environment: expanded_environment_name)
      project.ci_variables_for(ref: git_ref, environment: environment)
    end
  end
end
