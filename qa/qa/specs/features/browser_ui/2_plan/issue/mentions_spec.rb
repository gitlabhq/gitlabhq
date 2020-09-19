# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, :reliable do
    describe 'mention' do
      let(:user) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-to-test-mention'
          project.visibility = 'private'
        end
      end

      before do
        Flow::Login.sign_in

        project.add_member(user)

        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end.visit!
      end

      it 'mentions another user in an issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/446' do
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
