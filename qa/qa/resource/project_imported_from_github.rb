# frozen_string_literal: true

module QA
  module Resource
    class ProjectImportedFromGithub < Resource::Project
      attr_accessor :full_notes_import,
        :attachments_import,
        :allow_partial_import

      attribute :github_repo_id do
        github_client.repository(github_repository_path).id
      end

      def fabricate!
        self.import = true

        Page::Main::Menu.perform(&:go_to_create_project)

        go_to_import_page

        Page::Project::Import::Github.perform do |import_page|
          import_page.add_personal_access_token(github_personal_access_token)

          import_page.select_advanced_option(:single_endpoint_notes_import) if full_notes_import
          import_page.select_advanced_option(:attachments_import) if attachments_import

          import_page.import!(github_repository_path, group.full_path, name)
          import_page.wait_for_success(github_repository_path, wait: 240, allow_partial_import: allow_partial_import)
        end

        reload!
        visit!
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
        "#{Runtime::Scenario.gitlab_address}/#{full_path}"
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
          target_namespace: @personal_namespace || group.full_path,
          personal_access_token: github_personal_access_token,
          ci_cd_only: false,
          optional_stages: {
            single_endpoint_notes_import: full_notes_import,
            attachments_import: attachments_import
          }
        }.compact
      end

      def transform_api_resource(api_resource)
        api_resource
      end

      def trigger_project_mirror
        Runtime::Logger.info "Triggering pull mirror request"

        Support::Retrier.retry_until(max_attempts: 6, sleep_interval: 10) do
          response = post(request_url(api_trigger_mirror_pull_path), nil)

          Runtime::Logger.info "Mirror pull request response: #{response}"
          response.code == Support::API::HTTP_STATUS_OK
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
