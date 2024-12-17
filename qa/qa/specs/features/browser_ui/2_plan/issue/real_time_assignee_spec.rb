# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :requires_admin, product_group: :project_management do
    describe 'Assignees' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:project) { create(:project, name: 'project-to-test-assignees') }

      before do
        Flow::Login.sign_in

        project.add_member(user1)
        project.add_member(user2)
      end

      it 'update without refresh', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347941' do
        issue = create(:issue, project: project, assignee_ids: [user1.id])
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
