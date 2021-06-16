# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :requires_admin, :actioncable, :orchestrated do
    describe 'Assignees' do
      let(:user1) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:user2) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2) }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-to-test-assignees'
        end
      end

      before do
        Runtime::Feature.enable('real_time_issue_sidebar', project: project)
        Runtime::Feature.enable('broadcast_issue_updates', project: project)
        Runtime::Feature.enable(:invite_members_group_modal, project: project)

        Flow::Login.sign_in

        project.add_member(user1)
        project.add_member(user2)
      end

      after do
        Runtime::Feature.disable('real_time_issue_sidebar', project: project)
        Runtime::Feature.disable('broadcast_issue_updates', project: project)
        Runtime::Feature.disable(:invite_members_group_modal, project: project)
      end

      it 'update without refresh', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1048' do
        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
          issue.assignee_ids = [user1.id]
        end

        issue.visit!

        Page::Project::Issue::Show.perform do |show|
          expect(show).to have_assignee(user1.name)
          # We need to wait 1 second for the page to connect to the websocket to subscribe to updates
          # https://gitlab.com/gitlab-org/gitlab/-/issues/293699#note_583959786
          sleep 1
          issue.set_issue_assignees(assignee_ids: [user2.id])

          expect(show).to have_assignee(user2.name)
          expect(show).not_to have_assignee(user1.name)

          issue.set_issue_assignees(assignee_ids: [])

          expect(show).not_to have_assignee(user1.name)
          expect(show).not_to have_assignee(user2.name)
        end
      end
    end
  end
end
