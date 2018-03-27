require 'rails_helper'

feature 'Issue awards', :js do
  let(:user)      { create(:user) }
  let(:project)   { create(:project, :public) }
  let(:issue)     { create(:issue, project: project) }

  describe 'logged in' do
    before do
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_requests
    end

    it 'adds award to issue' do
      first('.js-emoji-btn').click
      expect(page).to have_selector('.js-emoji-btn.active')
      expect(first('.js-emoji-btn')).to have_content '1'

      visit project_issue_path(project, issue)
      expect(first('.js-emoji-btn')).to have_content '1'
    end

    it 'removes award from issue' do
      first('.js-emoji-btn').click
      find('.js-emoji-btn.active').click
      expect(first('.js-emoji-btn')).to have_content '0'

      visit project_issue_path(project, issue)
      expect(first('.js-emoji-btn')).to have_content '0'
    end

    it 'only has one menu on the page' do
      first('.js-add-award').click
      expect(page).to have_selector('.emoji-menu')

      expect(page).to have_selector('.emoji-menu', count: 1)
    end
  end

  describe 'logged out' do
    before do
      visit project_issue_path(project, issue)
      wait_for_requests
    end

    it 'does not see award menu button' do
      expect(page).not_to have_selector('.js-award-holder')
    end
  end
end
