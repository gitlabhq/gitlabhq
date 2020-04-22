# frozen_string_literal: true

module QA
  context 'Plan', :reliable do
    describe 'check xss occurence in @mentions in issues', :requires_admin do
      let(:user) do
        Resource::User.fabricate_via_api! do |user|
          user.name = "eve <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;"
          user.password = "test1234"
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'xss-test-for-mentions-project'
          project.add_member(user)
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end
      end

      before do
        QA::Runtime::Env.personal_access_token = QA::Runtime::Env.admin_personal_access_token

        unless QA::Runtime::Env.personal_access_token
          Flow::Login.sign_in_as_admin
        end

        QA::Runtime::Env.personal_access_token = nil

        Page::Main::Menu.perform(&:sign_out) if Page::Main::Menu.perform { |p| p.has_personal_area?(wait: 0) }

        Flow::Login.sign_in
      end

      it 'mentions a user in a comment' do
        issue.visit!

        Page::Project::Issue::Show.perform do |show|
          show.select_all_activities_filter
          show.comment("cc-ing you here @#{user.username}")

          expect do
            expect(show).to have_comment("cc-ing you here")
          end.not_to raise_error # Selenium::WebDriver::Error::UnhandledAlertError
        end
      end
    end
  end
end
