require 'rails_helper'

describe 'Manually create a todo item from epic', :js do
  let(:group) { create(:group) }
  let(:epic)   { create(:epic, group: group) }
  let(:user)    { create(:user)}

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
    visit group_epic_path(group, epic)
  end

  it 'creates todo when clicking button' do
    page.within '.issuable-sidebar' do
      click_button 'Add todo'

      expect(page).to have_content 'Mark todo as done'
    end

    page.within '.header-content .todos-count' do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    page.within '.issuable-sidebar' do
      click_button 'Add todo'
    end

    expect(page).to have_selector('.todos-count', visible: true)
    page.within '.header-content .todos-count' do
      expect(page).to have_content '1'
    end

    page.within '.issuable-sidebar' do
      click_button 'Mark todo as done'
    end

    expect(page).to have_selector('.todos-count', visible: false)
  end
end
