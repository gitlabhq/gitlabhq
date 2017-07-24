require 'spec_helper'

describe 'issue boards', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let!(:board) { create(:board, project: project) }

  before do
    project.add_developer(user)
    login_as(user)
  end

  context 'issue board focus mode' do
    it 'shows the button when the feature is enabled' do
      stub_licensed_features(issue_board_focus_mode: true)

      visit_board_page

      expect(page).to have_link('Toggle focus mode')
    end

    it 'hides the button when the feature is enabled' do
      stub_licensed_features(issue_board_focus_mode: false)

      visit_board_page

      expect(page).not_to have_link('Toggle focus mode')
    end
  end

  def visit_board_page
    visit project_boards_path(project)
    wait_for_requests
  end
end
