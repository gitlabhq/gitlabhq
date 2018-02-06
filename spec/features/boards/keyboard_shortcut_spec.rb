require 'rails_helper'

describe 'Issue Boards shortcut', :js do
  context 'issues are enabled' do
    let(:project) { create(:project) }

    before do
      create(:board, project: project)

      sign_in(create(:admin))

      visit project_path(project)
    end

    it 'takes user to issue board index' do
      find('body').native.send_keys('gb')
      expect(page).to have_selector('.boards-list')

      wait_for_requests
    end
  end

  context 'issues are not enabled' do
    let(:project) { create(:project, :issues_disabled) }

    before do
      sign_in(create(:admin))

      visit project_path(project)
    end

    it 'does not take user to the issue board index' do
      find('body').native.send_keys('gb')

      expect(page).to have_selector("body[data-page='projects:show']")
    end
  end
end
