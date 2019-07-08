# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'check xss occurence in @mentions in issues' do
      let(:issue_title) { 'issue title' }

      it 'user mentions a user in comment' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        user = Resource::User.fabricate_via_api! do |user|
          user.name = "eve <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;"
          user.password = "test1234"
        end

        project = Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'xss-test-for-mentions-project'
        end
        project.visit!

        Page::Project::Show.perform(&:go_to_members_settings)
        Page::Project::Settings::Members.perform do |page|
          page.add_member(user.username)
        end

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = issue_title
          issue.project = project
        end
        issue.visit!

        Page::Project::Issue::Show.perform do |show_page|
          show_page.select_all_activities_filter
          show_page.comment('cc-ing you here @eve')

          expect do
            expect(show_page).to have_content("cc-ing you here")
          end.not_to raise_error # Selenium::WebDriver::Error::UnhandledAlertError
        end
      end
    end
  end
end
