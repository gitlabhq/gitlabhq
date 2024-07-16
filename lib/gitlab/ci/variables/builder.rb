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

        # Our goal is that job_attributes will eventually replace all job-related variables.
        def scoped_variables(job, environment:, dependencies:, job_attributes: {})
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.concat(predefined_variables(job, environment, job_attributes: job_attributes))
            variables.concat(project.predefined_variables)
            variables.concat(pipeline_variables_builder.predefined_variables)
            variables.concat(job.runner.predefined_variables) if job.runnable? && job.runner
            variables.concat(kubernetes_variables(environment: environment, job: job))

            if job_attributes.present?
              variables.concat(job_attributes[:yaml_variables])
            else
              variables.concat(job.yaml_variables)
            end

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
            variables.concat(kubernetes_variables(environment: environment, job: job))
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

        def kubernetes_variables(environment:, job:)
          ::Gitlab::Ci::Variables::Collection.new.tap do |collection|
            # NOTE: deployment_variables will be removed as part of cleanup for
            # https://gitlab.com/groups/gitlab-org/configure/-/epics/8
            # Until then, we need to make both the old and the new KUBECONFIG contexts available
            collection.concat(deployment_variables(environment: environment, job: job))
            template = ::Ci::GenerateKubeconfigService.new(pipeline, token: job.try(:token), environment: environment).execute
            kubeconfig_yaml = collection['KUBECONFIG']&.value
            template.merge_yaml(kubeconfig_yaml) if kubeconfig_yaml.present?

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

        def predefined_variables(job, environment, job_attributes: {})
          Gitlab::Ci::Variables::Collection.new.tap do |variables|
            variables.append(key: 'CI_JOB_NAME', value: job.name)
            variables.append(key: 'CI_JOB_NAME_SLUG', value: job_name_slug(job))
            variables.append(key: 'CI_JOB_STAGE', value: job.stage_name)
            variables.append(key: 'CI_JOB_MANUAL', value: 'true') if job.action?
            variables.append(key: 'CI_PIPELINE_TRIGGERED', value: 'true') if job.trigger_request
            variables.append(key: 'CI_TRIGGER_SHORT_TOKEN', value: job.trigger_short_token) if job.trigger_request

            if job_attributes.present?
              variables.append(key: 'CI_NODE_INDEX', value: job_attributes[:options][:instance].to_s) if job_attributes[:options]&.include?(:instance)
              variables.append(key: 'CI_NODE_TOTAL', value: ci_node_total_value(job_attributes[:options]).to_s)
            else
              variables.append(key: 'CI_NODE_INDEX', value: job.options[:instance].to_s) if job.options&.include?(:instance)
              variables.append(key: 'CI_NODE_TOTAL', value: ci_node_total_value(job.options).to_s)
            end

            if environment.present?
              variables.append(key: 'CI_ENVIRONMENT_NAME', value: environment)
              variables.append(key: 'CI_ENVIRONMENT_ACTION', value: job.environment_action)
              variables.append(key: 'CI_ENVIRONMENT_TIER', value: job.environment_tier)
              variables.append(key: 'CI_ENVIRONMENT_URL', value: job.environment_url) if job.environment_url
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

        def job_name_slug(job)
          job.name && Gitlab::Utils.slugify(job.name)
        end

        def ci_node_total_value(job_options)
          parallel = job_options&.dig(:parallel)
          parallel = parallel.dig(:total) if parallel.is_a?(Hash)
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
      end
    end
  end
end

Gitlab::Ci::Variables::Builder.prepend_mod_with('Gitlab::Ci::Variables::Builder')
