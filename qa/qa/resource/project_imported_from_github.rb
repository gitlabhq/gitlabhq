# frozen_string_literal: true

require 'octokit'

module QA
  module Resource
    class ProjectImportedFromGithub < Resource::Project
      attribute :github_repo_id do
        github_client.repository(github_repository_path).id
      end

      def fabricate!
        self.import = true

        Page::Main::Menu.perform(&:go_to_create_project)

        go_to_import_page

        Page::Project::Import::Github.perform do |import_page|
          import_page.add_personal_access_token(github_personal_access_token)
          import_page.import!(github_repository_path, name)
          import_page.go_to_project(name)
        end
      end

      def go_to_import_page
        Page::Project::New.perform do |project_page|
          project_page.click_import_project
          project_page.click_github_link
        end
      end

      def fabricate_via_api!
        super
      rescue ResourceURLMissingError
        "#{Runtime::Scenario.gitlab_address}/#{group.full_path}/#{name}"
      end

      def api_post_path
        '/import/github'
      end

      def api_trigger_mirror_pull_path
        "#{api_get_path}/mirror/pull"
      end

      def api_post_body
        {
          repo_id: github_repo_id,
          new_name: name,
          target_namespace: group.full_path,
          personal_access_token: github_personal_access_token,
          ci_cd_only: false
        }
      end

      def transform_api_resource(api_resource)
        api_resource
      end

      def trigger_project_mirror
        Runtime::Logger.info "Triggering pull mirror request"

        Support::Retrier.retry_until(max_attempts: 6, sleep_interval: 10) do
          response = post(request_url(api_trigger_mirror_pull_path), nil)

          Runtime::Logger.info "Mirror pull request response: #{response}"
          response.code == Support::Api::HTTP_STATUS_OK
        end
      end

      private

      # Github client
      #
      # @return [Octokit::Client]
      def github_client
        @github_client ||= Octokit::Client.new(access_token: github_personal_access_token)
      end
    end
  end
end
