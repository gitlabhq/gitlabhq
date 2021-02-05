# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Jira issue import', :jira, :orchestrated, :requires_admin do
      let(:jira_project_key) { "JITD" }
      let(:jira_issue_title) { "[#{jira_project_key}-1] Jira to GitLab Test Issue" }
      let(:jira_issue_description) { "This issue is for testing importing Jira issues to GitLab." }
      let(:jira_issue_label_1) { "jira-import::#{jira_project_key}-1" }
      let(:jira_issue_label_2) { "QA" }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "jira_issue_import"
        end
      end

      it 'imports issues from Jira', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/896' do
        set_up_jira_integration
        import_jira_issues

        QA::Support::Retrier.retry_on_exception do
          Page::Project::Menu.perform(&:click_issues)

          Page::Project::Issue::Index.perform do |issues_page|
            expect(issues_page).to have_content("2 issues successfully imported")

            issues_page.click_issue_link(jira_issue_title)
          end
        end

        expect(page).to have_content(jira_issue_description)

        Page::Project::Issue::Show.perform do |issue|
          expect(issue).to have_label(jira_issue_label_1)
          expect(issue).to have_label(jira_issue_label_2)
        end
      end

      private

      def set_up_jira_integration
        Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)

        page.visit Runtime::Scenario.gitlab_address
        Flow::Login.sign_in_unless_signed_in

        project.visit!

        Page::Project::Menu.perform(&:go_to_integrations_settings)
        QA::Page::Project::Settings::Integrations.perform(&:click_jira_link)

        QA::Page::Project::Settings::Services::Jira.perform do |jira|
          jira.setup_service_with(url: Vendor::Jira::JiraAPI.perform(&:base_url))
        end

        expect(page).not_to have_text("Url is blocked")
        expect(page).to have_text("Jira settings saved and active.")
      end

      def import_jira_issues
        Page::Project::Menu.perform(&:click_issues)
        Page::Project::Issue::Index.perform(&:go_to_jira_import_form)

        Page::Project::Issue::JiraImport.perform do |form|
          form.select_project_and_import(jira_project_key)
        end

        expect(page).to have_content("Import in progress")
      end
    end
  end
end
