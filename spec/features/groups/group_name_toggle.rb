require 'spec_helper'

feature 'Group name toggle', js: true do
  let(:group) { create(:group) }
  let(:nested_group_1) { create(:group, parent: group) }
  let(:nested_group_2) { create(:group, parent: nested_group_1) }
  let(:nested_group_3) { create(:group, parent: nested_group_2) }

  before do
    login_as :user
  end

  it 'is not present for less than 3 groups' do
    visit group_path(group)
    expect(page).not_to have_css('.group-name-toggle')

    visit group_path(nested_group_1)
    expect(page).not_to have_css('.group-name-toggle')
  end

  it 'is present for nested group of 3 or more in the namespace' do
    visit group_path(nested_group_2)
    expect(page).to have_css('.group-name-toggle')

    visit group_path(nested_group_3)
    expect(page).to have_css('.group-name-toggle')
  end

  context 'for group with at least 3 groups' do
    before do
      visit group_path(nested_group_2)
    end

    it 'should show the full group namespace when toggled' do
      expect(page).not_to have_content(group.name)
      expect(page).to have_css('.group-path.hidable', visible: false)

      click_button '...'

      expect(page).to have_content(group.name)
      expect(page).to have_css('.group-path.hidable', visible: true)
    end
  end
end
