# frozen_string_literal: true

module QA
  context 'Plan', :smoke do
    describe 'mention' do
      before do
        Flow::Login.sign_in

        @user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

        project = Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'project-to-test-mention'
          resource.visibility = 'private'
        end
        project.visit!

        Page::Project::Show.perform(&:go_to_members_settings)
        Page::Project::Settings::Members.perform do |members|
          members.add_member(@user.username)
        end

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'issue to test mention'
          issue.project = project
        end
        issue.visit!
      end

      it 'user mentions another user in an issue' do
        Page::Project::Issue::Show.perform do |show|
          at_username = "@#{@user.username}"

          show.select_all_activities_filter
          show.comment(at_username)

          expect(show).to have_link(at_username)
        end
      end
    end
  end
end
