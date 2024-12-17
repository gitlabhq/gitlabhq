# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        include ::Gitlab::Utils::StrongMemoize

        def initialize(pipeline)
          @pipeline = pipeline
          @pipeline_variables_builder = Builder::Pipeline.new(pipeline)
          @instance_variables_builder = Builder::Instance.new
          @project_variables_builder = Builder::Project.new(project)
          @group_variables_builder = Builder::Group.new(project&.group)
          @release_variables_builder = Builder::Release.new(release)
        end

        # When adding new variables, consider either adding or commenting out them in the following methods:
        # - unprotected_scoped_variables
        # - scoped_variables_for_pipeline_seed
        def scoped_variables(job, environment:, dependencies:)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.concat(predefined_variables(job, environment))
            variables.concat(project.predefined_variables)
            variables.concat(pipeline_variables_builder.predefined_variables)
            variables.concat(job.runner.predefined_variables) if job.runnable? && job.runner
            variables.concat(kubernetes_variables_from_job(environment: environment, job: job))
            variables.concat(job.yaml_variables)
            variables.concat(user_variables(job.user))
            variables.concat(job.dependency_variables) if dependencies
            variables.concat(secret_instance_variables)
            variables.concat(secret_group_variables(environment: environment))
            variables.concat(secret_project_variables(environment: environment))
            variables.concat(pipeline.variables)
            variables.concat(pipeline_schedule_variables)
            variables.concat(release_variables)
          end
        end

        def unprotected_scoped_variables(job, expose_project_variables:, expose_group_variables:, environment:, dependencies:)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.concat(predefined_variables(job, environment))
            variables.concat(project.predefined_variables)
            variables.concat(pipeline_variables_builder.predefined_variables)
            variables.concat(job.runner.predefined_variables) if job.runnable? && job.runner
            variables.concat(kubernetes_variables_from_job(environment: environment, job: job))
            variables.concat(job.yaml_variables)
            variables.concat(user_variables(job.user))
            variables.concat(job.dependency_variables) if dependencies
            variables.concat(secret_instance_variables)
            variables.concat(secret_group_variables(environment: environment, include_protected_vars: expose_group_variables))
            variables.concat(secret_project_variables(environment: environment, include_protected_vars: expose_project_variables))
            variables.concat(pipeline.variables)
            variables.concat(pipeline_schedule_variables)
            variables.concat(release_variables)
          end
        end

        def scoped_variables_for_pipeline_seed(job_attr, environment:, kubernetes_namespace:, user:, trigger_request:)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.concat(predefined_variables_from_job_attr(job_attr, environment, trigger_request))
            variables.concat(project.predefined_variables)
            variables.concat(pipeline_variables_builder.predefined_variables)
            # job.runner.predefined_variables: No need because it's not available in the Seed step.
            variables.concat(kubernetes_variables_from_attr(environment: environment, kubernetes_namespace: kubernetes_namespace))
            variables.concat(job_attr[:yaml_variables])
            variables.concat(user_variables(user))
            # job.dependency_variables: No need because dependencies are not in the Seed step.
            variables.concat(secret_instance_variables)
            variables.concat(secret_group_variables(environment: environment))
            variables.concat(secret_project_variables(environment: environment))
            variables.concat(pipeline.variables)
            variables.concat(pipeline_schedule_variables)
            variables.concat(release_variables)
          end
        end

        def config_variables
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            break variables unless project

            variables.concat(project.predefined_variables)
            variables.concat(pipeline_variables_builder.predefined_variables)
            variables.concat(secret_instance_variables)
            variables.concat(secret_group_variables(environment: nil))
            variables.concat(secret_project_variables(environment: nil))
            variables.concat(pipeline.variables)
            variables.concat(pipeline_schedule_variables)
          end
        end

        def kubernetes_variables(environment:, token:, kubernetes_namespace:)
          ::Gitlab::Ci::Variables::Collection.new.tap do |collection|
            # NOTE: deployment_variables will be removed as part of cleanup for
            # https://gitlab.com/groups/gitlab-org/configure/-/epics/8
            # Until then, we need to make both the old and the new KUBECONFIG contexts available
            collection.concat(deployment_variables(environment, kubernetes_namespace))
            collection.concat(kubeconfig_variables(environment, kubernetes_namespace, token, collection['KUBECONFIG']&.value))
          end
        end

        def deployment_variables(environment, kubernetes_namespace)
          strong_memoize_with(:deployment_variables, environment, kubernetes_namespace) do
            next [] unless environment

            project.deployment_variables(
              environment: environment,
              kubernetes_namespace: kubernetes_namespace
            )
          end
        end

        def kubeconfig_variables(environment, kubernetes_namespace, token, kubeconfig_yaml)
          # kubernetes_namespace is part of the cache key because the value of KUBECONFIG depends on it.
          # And we don't want to use `kubeconfig_yaml` in the cache key because it can be too large.
          strong_memoize_with(:kubeconfig_variables, environment, token, kubernetes_namespace) do
            template = ::Ci::GenerateKubeconfigService.new(pipeline, token: token, environment: environment).execute
            template.merge_yaml(kubeconfig_yaml) if kubeconfig_yaml.present?

            next [] unless template.valid?

            ::Gitlab::Ci::Variables::Collection.new.tap do |collection|
              collection.append(key: 'KUBECONFIG', value: template.to_yaml, public: false, file: true)
            end
          end
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

        def secret_group_variables(environment:, include_protected_vars: protected_ref?)
          strong_memoize_with(:secret_group_variables, environment, include_protected_vars) do
            group_variables_builder
              .secret_variables(
                environment: environment,
                protected_ref: include_protected_vars)
          end
        end

        def secret_project_variables(environment:, include_protected_vars: protected_ref?)
          strong_memoize_with(:secret_project_variables, environment, include_protected_vars) do
            project_variables_builder
              .secret_variables(
                environment: environment,
                protected_ref: include_protected_vars)
          end
        end

        def release_variables
          strong_memoize(:release_variables) do
            release_variables_builder.variables
          end
        end

        private

        attr_reader :pipeline
        attr_reader :pipeline_variables_builder
        attr_reader :instance_variables_builder
        attr_reader :project_variables_builder
        attr_reader :group_variables_builder
        attr_reader :release_variables_builder

        delegate :project, to: :pipeline

        def predefined_variables(job, environment)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.append(key: 'CI_JOB_NAME', value: job.name)
            variables.append(key: 'CI_JOB_NAME_SLUG', value: job_name_slug(job.name))
            variables.append(key: 'CI_JOB_STAGE', value: job.stage_name)
            variables.append(key: 'CI_JOB_MANUAL', value: 'true') if job.action?
            variables.append(key: 'CI_PIPELINE_TRIGGERED', value: 'true') if job.trigger_request
            variables.append(key: 'CI_TRIGGER_SHORT_TOKEN', value: job.trigger_short_token) if job.trigger_request

            variables.append(key: 'CI_NODE_INDEX', value: job.options[:instance].to_s) if job.options&.include?(:instance)
            variables.append(key: 'CI_NODE_TOTAL', value: ci_node_total_value(job.options).to_s)

            if environment.present?
              variables.append(key: 'CI_ENVIRONMENT_NAME', value: environment)
              variables.append(key: 'CI_ENVIRONMENT_ACTION', value: job.environment_action)
              variables.append(key: 'CI_ENVIRONMENT_TIER', value: job.environment_tier)
              variables.append(key: 'CI_ENVIRONMENT_URL', value: job.environment_url) if job.environment_url
            end
          end
        end

        def predefined_variables_from_job_attr(job_attr, environment, trigger_request)
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.append(key: 'CI_JOB_NAME', value: job_attr[:name])
            variables.append(key: 'CI_JOB_NAME_SLUG', value: job_name_slug(job_attr[:name]))
            variables.append(key: 'CI_JOB_STAGE', value: job_attr[:stage])
            variables.append(key: 'CI_JOB_MANUAL', value: 'true') if ::Ci::Processable::ACTIONABLE_WHEN.include?(job_attr[:when])
            variables.append(key: 'CI_PIPELINE_TRIGGERED', value: 'true') if trigger_request
            variables.append(key: 'CI_TRIGGER_SHORT_TOKEN', value: trigger_request.trigger_short_token) if trigger_request
            variables.append(key: 'CI_NODE_INDEX', value: job_attr[:options][:instance].to_s) if job_attr[:options]&.include?(:instance)
            variables.append(key: 'CI_NODE_TOTAL', value: ci_node_total_value(job_attr[:options]).to_s)

            if environment.present?
              variables.append(key: 'CI_ENVIRONMENT_NAME', value: environment)

              if job_attr[:options].present?
                variables.append(key: 'CI_ENVIRONMENT_ACTION', value: environment_action_from_job_options(job_attr[:options]))
                variables.append(key: 'CI_ENVIRONMENT_TIER', value: environment_tier_from_job_options(job_attr[:options], environment))
                variables.append(key: 'CI_ENVIRONMENT_URL', value: environment_url_from_job_options(job_attr[:options], environment))
              end
            end
          end
        end

        def pipeline_schedule_variables
          strong_memoize(:pipeline_schedule_variables) do
            variables = if pipeline.pipeline_schedule
                          pipeline.pipeline_schedule.job_variables
                        else
                          []
                        end

            Gitlab::Ci::Variables::Collection.new(variables)
          end
        end

        def kubernetes_variables_from_attr(environment:, kubernetes_namespace:)
          kubernetes_variables(
            environment: environment,
            token: nil,
            kubernetes_namespace: kubernetes_namespace
          )
        end

        def kubernetes_variables_from_job(environment:, job:)
          kubernetes_variables(
            environment: environment,
            token: job.try(:token),
            kubernetes_namespace: environment ? job.expanded_kubernetes_namespace : nil
            # environment.nil? means also that this is called from `simple_variables`.
          )
        end

        def job_name_slug(job_name)
          job_name && Gitlab::Utils.slugify(job_name)
        end

        def ci_node_total_value(job_options)
          parallel = job_options&.dig(:parallel)
          parallel = parallel[:total] if parallel.is_a?(Hash)
          parallel || 1
        end

        def protected_ref?
          strong_memoize(:protected_ref) do
            project.protected_for?(pipeline.jobs_git_ref)
          end
        end

        def release
          return unless @pipeline.tag?

          project.releases.find_by_tag(@pipeline.ref)
        end

        def environment_action_from_job_options(options)
          options.fetch(:environment, {}).fetch(:action, 'start')
        end

        # We use the `environment` parameter instead of `options[:environment]` because `environment` is expanded.
        def environment_tier_from_job_options(options, environment)
          options.dig(:environment, :deployment_tier) || persisted_environment(environment).try(:tier)
        end

        # We use the `environment` parameter instead of `options[:environment]` because `environment` is expanded.
        def environment_url_from_job_options(options, environment)
          options.dig(:environment, :url) || persisted_environment(environment).try(:external_url)
        end

        def persisted_environment(environment)
          strong_memoize_with(:persisted_environment, environment) do
            project.batch_loaded_environment_by_name(environment)
          end
        end
      end
    end
  end
end

Gitlab::Ci::Variables::Builder.prepend_mod_with('Gitlab::Ci::Variables::Builder')
