# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    let!(:user) do
      Resource::User.fabricate_via_api! do |user|
        user.name = "eve <img src=x onerror=alert(2)&lt;img src=x onerror=alert(1)&gt;"
        user.password = "test1234"
        user.api_client = Runtime::API::Client.as_admin
      end
    end

    let!(:project) do
      Resource::Project.fabricate_via_api! do |project|
        project.name = 'xss-test-for-mentions-project'
      end
    end

    describe 'check xss occurence in @mentions in issues', :requires_admin do
      before do
        Runtime::Feature.enable(:invite_members_group_modal)

        Flow::Login.sign_in

        project.add_member(user)

        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end.visit!
      end

      after do
        user&.remove_via_api!
      end

      it 'mentions a user in a comment', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/452' do
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
