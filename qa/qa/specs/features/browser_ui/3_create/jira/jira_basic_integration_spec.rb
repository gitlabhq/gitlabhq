# frozen_string_literal: true

module QA
  context 'Create' do
    include Support::Api

    describe 'Jira integration', :jira, :orchestrated, :requires_admin do
      let(:jira_project_key) { 'JITP' }

      before(:all) do
        page.visit Vendor::Jira::JiraAPI.perform(&:base_url)

        QA::Support::Retrier.retry_until(sleep_interval: 3, reload_page: page, max_attempts: 20, raise_on_failure: true) do
          page.has_text? 'Welcome to Jira'
        end

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = "project_with_jira_integration"
        end

        # Retry is required because allow_local_requests_from_web_hooks_and_services
        # takes some time to get enabled.
        # Bug issue: https://gitlab.com/gitlab-org/gitlab/-/issues/217010
        QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 3) do
          Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)

          page.visit Runtime::Scenario.gitlab_address
          Flow::Login.sign_in_unless_signed_in

          @project.visit!

          Page::Project::Menu.perform(&:go_to_integrations_settings)
          QA::Page::Project::Settings::Integrations.perform(&:click_jira_link)

          QA::Page::Project::Settings::Services::Jira.perform do |jira|
            jira.setup_service_with(url: Vendor::Jira::JiraAPI.perform(&:base_url))
          end

          expect(page).not_to have_text("Requests to the local network are not allowed")
        end
      end

      it 'closes an issue via pushing a commit' do
        issue_key = Vendor::Jira::JiraAPI.perform do |jira_api|
          jira_api.create_issue(jira_project_key)
        end

        push_commit("Closes #{issue_key}")

        expect_issue_done(issue_key)
      end

      it 'closes an issue via a merge request' do
        issue_key = Vendor::Jira::JiraAPI.perform do |jira_api|
          jira_api.create_issue(jira_project_key)
        end

        page.visit Runtime::Scenario.gitlab_address
        Flow::Login.sign_in_unless_signed_in

        merge_request = create_mr_with_description("Closes #{issue_key}")

        merge_request.visit!

        Page::MergeRequest::Show.perform(&:merge!)

        expect_issue_done(issue_key)
      end

      def create_mr_with_description(description)
        Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.project = @project
          merge_request.target_new_branch = !master_branch_exists?
          merge_request.description = description
        end
      end

      def push_commit(commit_message)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.branch_name = 'master'
          push.commit_message = commit_message
          push.file_content = commit_message
          push.project = @project
          push.new_branch = !master_branch_exists?
        end
      end

      def expect_issue_done(issue_key)
        expect do
          Support::Waiter.wait_until(raise_on_failure: true) do
            jira_issue = Vendor::Jira::JiraAPI.perform do |jira_api|
              jira_api.fetch_issue(issue_key)
            end

            jira_issue[:fields][:status][:name] == 'Done'
          end
        end.not_to raise_error
      end

      def master_branch_exists?
        @project.repository_branches.map { |item| item[:name] }.include?("master")
      end
    end
  end
end
