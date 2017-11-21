require 'spec_helper'

feature 'Update Epic', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete entry 1
    MARKDOWN
  end

  let(:epic) { create(:epic, group: group, description: markdown) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when user who is not a group member displays the epic' do
    it 'does not show the Edit button' do
      visit group_epic_path(group, epic)

      expect(page).not_to have_selector('.btn-edit')
    end
  end

  context 'when user with developer access displays the epic' do

    before do
      group.add_developer(user)
      visit group_epic_path(group, epic)
      wait_for_requests
    end

    it 'updates the issue' do
      find('.btn-edit').click

      fill_in 'issuable-title', with: 'New epic title'
      fill_in 'issue-description', with: 'New epic description'
      click_button 'Save changes'

      expect(find('.issuable-details h2.title')).to have_content('New epic title')
      expect(find('.issuable-details .description')).to have_content('New epic description')
    end

    it 'updates the tasklist' do
      expect(page).to have_selector('ul.task-list',      count: 1)
      expect(page).to have_selector('li.task-list-item', count: 1)
      expect(page).to have_selector('ul input[checked]', count: 0)

      find('.task-list .task-list-item', text: 'Incomplete entry 1').find('input').click

      expect(page).to have_selector('ul input[checked]', count: 1)
    end
  end
end
