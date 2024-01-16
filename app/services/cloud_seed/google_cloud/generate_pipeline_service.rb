# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class GeneratePipelineService < ::CloudSeed::GoogleCloud::BaseService
      ACTION_DEPLOY_TO_CLOUD_RUN = 'DEPLOY_TO_CLOUD_RUN'
      ACTION_DEPLOY_TO_CLOUD_STORAGE = 'DEPLOY_TO_CLOUD_STORAGE'
      ACTION_VISION_AI_PIPELINE = 'VISION_AI_PIPELINE'

      def execute
        commit_attributes = generate_commit_attributes
        create_branch_response = ::Branches::CreateService.new(project, current_user)
                                                          .execute(commit_attributes[:branch_name], project.default_branch)

        if create_branch_response[:status] == :error
          return create_branch_response
        end

        branch = create_branch_response[:branch]

        service = default_branch_gitlab_ci_yml.present? ? ::Files::UpdateService : ::Files::CreateService

        commit_response = service.new(project, current_user, commit_attributes).execute

        if commit_response[:status] == :error
          return commit_response
        end

        success({ branch_name: branch.name, commit: commit_response })
      end

      private

      def action
        @params[:action]
      end

      def generate_commit_attributes
        case action
        when ACTION_DEPLOY_TO_CLOUD_RUN
          branch_name = "deploy-to-cloud-run-#{SecureRandom.hex(8)}"
          {
            commit_message: 'Enable Cloud Run deployments',
            file_path: '.gitlab-ci.yml',
            file_content: pipeline_content('gcp/cloud-run.gitlab-ci.yml'),
            branch_name: branch_name,
            start_branch: branch_name
          }
        when ACTION_DEPLOY_TO_CLOUD_STORAGE
          branch_name = "deploy-to-cloud-storage-#{SecureRandom.hex(8)}"
          {
            commit_message: 'Enable Cloud Storage deployments',
            file_path: '.gitlab-ci.yml',
            file_content: pipeline_content('gcp/cloud-storage.gitlab-ci.yml'),
            branch_name: branch_name,
            start_branch: branch_name
          }
        when ACTION_VISION_AI_PIPELINE
          branch_name = "vision-ai-pipeline-#{SecureRandom.hex(8)}"
          {
            commit_message: 'Enable Vision AI Pipeline',
            file_path: '.gitlab-ci.yml',
            file_content: pipeline_content('gcp/vision-ai.gitlab-ci.yml'),
            branch_name: branch_name,
            start_branch: branch_name
          }
        end
      end

      def default_branch_gitlab_ci_yml
        @default_branch_gitlab_ci_yml ||= project.ci_config_for(project.default_branch)
      end

      def pipeline_content(include_path)
        gitlab_ci_yml = ::Gitlab::Ci::Config::Yaml::Loader.new(default_branch_gitlab_ci_yml || '{}').load

        append_remote_include(
          gitlab_ci_yml.content,
          "https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library/-/raw/main/#{include_path}"
        )
      end

      def append_remote_include(gitlab_ci_yml, include_url)
        stages = gitlab_ci_yml['stages'] || []
        gitlab_ci_yml['stages'] = if action == ACTION_VISION_AI_PIPELINE
                                    (stages + %w[validate detect render]).uniq
                                  else
                                    (stages + %w[build test deploy]).uniq
                                  end

        includes = gitlab_ci_yml['include'] || []
        includes = Array.wrap(includes)
        includes << { 'remote' => include_url }
        gitlab_ci_yml['include'] = includes.uniq

        gitlab_ci_yml.deep_stringify_keys.to_yaml
      end
    end
  end
end
