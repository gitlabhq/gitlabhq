require 'spec_helper'

describe 'issue boards', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:board) { create(:board, project: project) }

  before do
    project.add_developer(user)
    login_as(user)
  end

  context 'validations' do
    context 'when group is present' do
      it 'does not validate project presence' do
        group = create(:group)

        board = described_class.new(group: group)

        expect(board).not_to validate_presence_of(:project)
        expect(board).to validate_presence_of(:group)
      end
    end

    context 'when project is present' do
      it 'does not validate group presence' do
        project = create(:project)

        board = described_class.new(project: project)

        expect(board).to validate_presence_of(:project)
        expect(board).not_to validate_presence_of(:group)
      end
    end
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
