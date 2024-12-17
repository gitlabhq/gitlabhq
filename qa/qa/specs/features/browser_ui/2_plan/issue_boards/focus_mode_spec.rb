# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :project_management do
    describe 'Issue board focus mode' do
      let(:project) { create(:project, name: 'sample-project-issue-board-focus-mode') }

      before do
        Flow::Login.sign_in
      end

      it 'focuses on issue board', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347996' do
        project.visit!

        Page::Project::Menu.perform(&:go_to_issue_boards)
        Page::Component::IssueBoard::Show.perform do |show|
          show.click_focus_mode_button

          expect(show.focused_board).to be_visible
        end
      end
    end
  end
end
