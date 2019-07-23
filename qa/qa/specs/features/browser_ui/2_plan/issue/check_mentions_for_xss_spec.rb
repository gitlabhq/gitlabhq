# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'check xss occurence in @mentions in issues' do
      before do
        QA::Runtime::Env.personal_access_token = QA::Runtime::Env.admin_personal_access_token

        unless QA::Runtime::Env.personal_access_token
          Runtime::Browser.visit(:gitlab, Page::Main::Login)
          Page::Main::Login.perform(&:sign_in_using_admin_credentials)
        end

        user = Resource::User.fabricate_via_api! do |user|
          user.name = "eve <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;"
          user.password = "test1234"
        end

        QA::Runtime::Env.personal_access_token = nil

        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Menu.perform(&:sign_out) if Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }

        Page::Main::Login.perform(&:sign_in_using_credentials)

        project = Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'xss-test-for-mentions-project'
        end
        project.visit!

        Page::Project::Show.perform(&:go_to_members_settings)
        Page::Project::Settings::Members.perform do |page|
          page.add_member(user.username)
        end

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'issue title'
          issue.project = project
        end
        issue.visit!
      end

      it 'user mentions a user in comment' do
        Page::Project::Issue::Show.perform do |show|
          show.select_all_activities_filter
          show.comment('cc-ing you here @eve')

          expect do
            expect(show).to have_content("cc-ing you here")
          end.not_to raise_error # Selenium::WebDriver::Error::UnhandledAlertError
        end
      end
    end
  end
end
