# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, product_group: :project_management do
    describe 'mention' do
      let(:user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let(:project) do
        Resource::Project.fabricate_via_api_unless_fips! do |project|
          project.name = 'project-to-test-mention'
          project.visibility = 'private'
        end
      end

      before do
        Flow::Login.sign_in

        if Runtime::Env.personal_access_tokens_disabled?
          # Ensure user exists
          user
          Flow::Login.sign_in_as_admin
          project.visit!
          Page::Project::Menu.perform(&:click_members)
          Page::Project::Members.perform do |members|
            members.add_member(user.username)
          end
        else
          project.visit!
          project.add_member(user)
        end

        if Runtime::Env.personal_access_tokens_disabled?
          Resource::Issue.fabricate_via_browser_ui! do |issue|
            issue.project = project
          end.visit!
        else
          Resource::Issue.fabricate_via_api! do |issue|
            issue.project = project
          end.visit!
        end
      end

      it 'mentions another user in an issue',
testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347988' do
        Page::Project::Issue::Show.perform do |show|
          at_username = "@#{user.username}"

          show.select_all_activities_filter
          show.comment(at_username)

          expect(show).to have_link(at_username)
        end
      end
    end
  end
end
