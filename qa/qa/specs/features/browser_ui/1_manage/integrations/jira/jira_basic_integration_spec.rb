# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    include Support::API

    describe 'Jira integration', :jira, :orchestrated, :requires_admin, product_group: :import_and_integrate do
      let(:jira_project_key) { 'JITP' }
      let(:project) { create(:project, name: 'project_with_jira_integration') }

      before do
        page.visit Vendor::Jira::JiraAPI.perform(&:base_url)

        QA::Support::Retrier
          .retry_until(sleep_interval: 3, reload_page: page, max_attempts: 20, raise_on_failure: true) do
          page.has_text? 'Welcome to Jira'
        end

        Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)

        page.visit Runtime::Scenario.gitlab_address
        Flow::Login.sign_in_unless_signed_in

        project.visit!

        Page::Project::Menu.perform(&:go_to_integrations_settings)
        QA::Page::Project::Settings::Integrations.perform(&:click_jira_link)

        QA::Page::Project::Settings::Services::Jira.perform do |jira|
          jira.setup_service_with(url: Vendor::Jira::JiraAPI.perform(&:base_url))
        end

        expect(page).not_to have_text("Requests to the local network are not allowed") # rubocop:disable RSpec/ExpectInHook
      end

      it 'closes an issue via pushing a commit',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347794' do
        issue_key = Vendor::Jira::JiraAPI.perform do |jira_api|
          jira_api.create_issue(jira_project_key)
        end

        push_commit("Closes #{issue_key}")

        expect_issue_done(issue_key)
      end

      it 'closes an issue via a merge request',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347795' do
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

      private

      def create_mr_with_description(description)
        Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.project = project
          merge_request.target_new_branch = !master_branch_exists?
          merge_request.description = description
        end
      end

      def push_commit(commit_message)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.commit_message = commit_message
          push.file_content = commit_message
          push.project = project
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
        project.repository_branches.map { |item| item[:name] }.include?(project.default_branch)
      end
    end
  end
end
