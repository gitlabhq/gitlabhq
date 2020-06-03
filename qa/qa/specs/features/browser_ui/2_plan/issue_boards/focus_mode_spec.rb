# frozen_string_literal: true

module QA
  context 'Plan', :reliable do
    describe 'Issue board focus mode' do
      let(:project) do
        QA::Resource::Project.fabricate_via_api! do |project|
          project.name = 'sample-project-issue-board-focus-mode'
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'focuses on issue board' do
        project.visit!

        Page::Project::Menu.perform(&:go_to_boards)
        Page::Component::IssueBoard::Show.perform do |show|
          show.click_focus_mode_button

          expect(show.focused_board).to be_visible
        end
      end
    end
  end
end
