# frozen_string_literal: true

module Ai
  module DuoWorkflows
    class Workload < ::Ci::Workloads::Workload
      MAX_RUNTIME = 2.hours
      IMAGE = 'registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.4'

      def initialize(current_user, params)
        @params = params
        @current_user = current_user
      end

      def job
        {
          image: IMAGE,
          script: commands,
          timeout: "#{MAX_RUNTIME} seconds",
          variables: variables_without_expand,
          artifacts: {
            paths: artifacts_path
          }
        }
      end

      def artifacts_path
        []
      end

      def variables_without_expand
        # We set expand: false so that there is no way for user inputs (e.g. the goal) to expand out other variables
        variables.transform_values do |v|
          { value: v, expand: false }
        end
      end

      def variables
        {
          DUO_WORKFLOW_BASE_PATH: './',
          DUO_WORKFLOW_DEFINITION: @params[:workflow_definition],
          DUO_WORKFLOW_GOAL: @params[:goal],
          DUO_WORKFLOW_WORKFLOW_ID: String(@params[:workflow_id]),
          GITLAB_OAUTH_TOKEN: @params[:workflow_oauth_token],
          DUO_WORKFLOW_SERVICE_SERVER: Gitlab::DuoWorkflow::Client.url,
          DUO_WORKFLOW_SERVICE_TOKEN: @params[:workflow_service_token],
          DUO_WORKFLOW_SERVICE_REALM: ::CloudConnector.gitlab_realm,
          DUO_WORKFLOW_GLOBAL_USER_ID: Gitlab::GlobalAnonymousId.user_id(@current_user),
          DUO_WORKFLOW_INSTANCE_ID: Gitlab::GlobalAnonymousId.instance_id,
          DUO_WORKFLOW_INSECURE: Gitlab::DuoWorkflow::Client.secure? ? 'false' : 'true',
          DUO_WORKFLOW_DEBUG: Gitlab::DuoWorkflow::Client.debug_mode? ? 'true' : 'false',
          DUO_WORKFLOW_GIT_HTTP_BASE_URL: Gitlab.config.gitlab.url,
          DUO_WORKFLOW_GIT_HTTP_PASSWORD: @params[:workflow_oauth_token],
          DUO_WORKFLOW_GIT_HTTP_USER: "oauth",
          GITLAB_BASE_URL: Gitlab.config.gitlab.url
        }
      end

      def commands
        [
          %(echo $DUO_WORKFLOW_DEFINITION),
          %(echo $DUO_WORKFLOW_GOAL),
          %(git checkout #{@branch}),
          %(wget #{Gitlab::DuoWorkflow::Executor.executor_binary_url} -O /tmp/duo-workflow-executor.tar.gz),
          %(tar xf /tmp/duo-workflow-executor.tar.gz --directory /tmp),
          %(chmod +x /tmp/duo-workflow-executor),
          %(/tmp/duo-workflow-executor)
        ]
      end
    end
  end
end
