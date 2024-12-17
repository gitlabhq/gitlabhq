# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Jira issue import', :jira, :orchestrated, :requires_admin, product_group: :import_and_integrate do
      let(:jira_project_key) { "JITD" }
      let(:jira_issue_title) { "[#{jira_project_key}-1] Jira to GitLab Test Issue" }
      let(:jira_issue_description) { "This issue is for testing importing Jira issues to GitLab." }
      let(:jira_issue_label_1) { "jira-import::#{jira_project_key}-1" }
      let(:jira_issue_label_2) { "QA" }
      let(:project) { create(:project, name: "jira_issue_import") }

      it 'imports issues from Jira', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347966' do
        set_up_jira_integration
        import_jira_issues

        Page::Project::Menu.perform(&:go_to_issues)
        Page::Project::Issue::Index.perform do |issues_page|
          expect { issues_page }.to eventually_have_content(jira_issue_title).within(
            max_attempts: 5, sleep_interval: 1, reload_page: issues_page
          )
          issues_page.click_issue_link(jira_issue_title)
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
        expect(page).to have_text("Jira issues settings saved and active.")
      end

      def import_jira_issues
        Page::Project::Menu.perform(&:go_to_issues)
        Page::Project::Issue::Index.perform(&:go_to_jira_import_form)

        Page::Project::Issue::JiraImport.perform do |form|
          form.select_project_and_import(jira_project_key)
        end

        expect(page).to have_content("Import in progress")
      end
    end
  end
end
