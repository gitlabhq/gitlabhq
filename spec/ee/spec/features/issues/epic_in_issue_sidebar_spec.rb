require 'spec_helper'

describe 'Epic in issue sidebar', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:project) { create(:project, :public, group: group) }
  let(:issue) { create(:issue, project: project) }
  let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

  context 'when epics available' do
    before do
      stub_licensed_features(epics: true)
      sign_in(user)
      visit project_issue_path(project, issue)
    end

    it 'shows epic in issue sidebar' do
      expect(page.find('.block.epic .value')).to have_content(epic.title)
    end
  end

  context 'when epics unavailable' do
    before do
      stub_licensed_features(epics: false)
      sign_in(user)
      visit project_issue_path(project, issue)
    end

    it 'does not show epic in issue sidebar' do
      expect(page).not_to have_selector('.block.epic')
    end
  end
end
