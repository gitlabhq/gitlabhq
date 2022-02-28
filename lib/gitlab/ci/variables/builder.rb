# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        include ::Gitlab::Utils::StrongMemoize

        def initialize(pipeline)
          @pipeline = pipeline
          @instance_variables_builder = Builder::Instance.new
          @project_variables_builder = Builder::Project.new(project)
          @group_variables_builder = Builder::Group.new(project.group)
        end

        def scoped_variables(job, environment:, dependencies:)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.concat(predefined_variables(job))
            variables.concat(project.predefined_variables)
            variables.concat(pipeline.predefined_variables)
            variables.concat(job.runner.predefined_variables) if job.runnable? && job.runner
            variables.concat(kubernetes_variables(job))
            variables.concat(deployment_variables(environment: environment, job: job))
            variables.concat(job.yaml_variables)
            variables.concat(user_variables(job.user))
            variables.concat(job.dependency_variables) if dependencies
            variables.concat(secret_instance_variables)
            variables.concat(secret_group_variables(environment: environment, ref: job.git_ref))
            variables.concat(secret_project_variables(environment: environment, ref: job.git_ref))
            variables.concat(job.trigger_request.user_variables) if job.trigger_request
            variables.concat(pipeline.variables)
            variables.concat(pipeline.pipeline_schedule.job_variables) if pipeline.pipeline_schedule
          end
        end

        def kubernetes_variables(job)
          ::Gitlab::Ci::Variables::Collection.new.tap do |collection|
            # Should get merged with the cluster kubeconfig in deployment_variables, see
            # https://gitlab.com/gitlab-org/gitlab/-/issues/335089
            template = ::Ci::GenerateKubeconfigService.new(job).execute

            if template.valid?
              collection.append(key: 'KUBECONFIG', value: template.to_yaml, public: false, file: true)
            end
          end
        end

        def deployment_variables(environment:, job:)
          return [] unless environment

          project.deployment_variables(
            environment: environment,
            kubernetes_namespace: job.expanded_kubernetes_namespace
          )
        end

        def user_variables(user)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            break variables if user.blank?

            variables.append(key: 'GITLAB_USER_ID', value: user.id.to_s)
            variables.append(key: 'GITLAB_USER_EMAIL', value: user.email)
            variables.append(key: 'GITLAB_USER_LOGIN', value: user.username)
            variables.append(key: 'GITLAB_USER_NAME', value: user.name)
          end
        end

        def secret_instance_variables
          strong_memoize(:secret_instance_variables) do
            instance_variables_builder
              .secret_variables(protected_ref: protected_ref?)
          end
        end

        def secret_group_variables(environment:, ref:)
          if memoize_secret_variables?
            memoized_secret_group_variables(environment: environment)
          else
            return [] unless project.group

            project.group.ci_variables_for(ref, project, environment: environment)
          end
        end

        def secret_project_variables(environment:, ref:)
          if memoize_secret_variables?
            memoized_secret_project_variables(environment: environment)
          else
            project.ci_variables_for(ref: ref, environment: environment)
          end
        end

        private

        attr_reader :pipeline
        attr_reader :instance_variables_builder
        attr_reader :project_variables_builder
        attr_reader :group_variables_builder

        delegate :project, to: :pipeline

        def predefined_variables(job)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.append(key: 'CI_JOB_NAME', value: job.name)
            variables.append(key: 'CI_JOB_STAGE', value: job.stage)
            variables.append(key: 'CI_JOB_MANUAL', value: 'true') if job.action?
            variables.append(key: 'CI_PIPELINE_TRIGGERED', value: 'true') if job.trigger_request

            variables.append(key: 'CI_NODE_INDEX', value: job.options[:instance].to_s) if job.options&.include?(:instance)
            variables.append(key: 'CI_NODE_TOTAL', value: ci_node_total_value(job).to_s)

            # legacy variables
            variables.append(key: 'CI_BUILD_NAME', value: job.name)
            variables.append(key: 'CI_BUILD_STAGE', value: job.stage)
            variables.append(key: 'CI_BUILD_TRIGGERED', value: 'true') if job.trigger_request
            variables.append(key: 'CI_BUILD_MANUAL', value: 'true') if job.action?
          end
        end

        def memoized_secret_project_variables(environment:)
          strong_memoize_with(:secret_project_variables, environment) do
            project_variables_builder
              .secret_variables(
                environment: environment,
                protected_ref: protected_ref?)
          end
        end

        def memoized_secret_group_variables(environment:)
          strong_memoize_with(:secret_group_variables, environment) do
            group_variables_builder
              .secret_variables(
                environment: environment,
                protected_ref: protected_ref?)
          end
        end

        def ci_node_total_value(job)
          parallel = job.options&.dig(:parallel)
          parallel = parallel.dig(:total) if parallel.is_a?(Hash)
          parallel || 1
        end

        def protected_ref?
          strong_memoize(:protected_ref) do
            project.protected_for?(pipeline.jobs_git_ref)
          end
        end

        def memoize_secret_variables?
          strong_memoize(:memoize_secret_variables) do
            ::Feature.enabled?(:ci_variables_builder_memoize_secret_variables,
              project,
              default_enabled: :yaml)
          end
        end

        def strong_memoize_with(name, *args)
          container = strong_memoize(name) { {} }

          if container.key?(args)
            container[args]
          else
            container[args] = yield
          end
        end
      end
    end
  end
end
