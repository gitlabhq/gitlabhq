require 'spec_helper'

feature 'Group', feature: true do
  before do
    login_as(:admin)
  end

  describe 'creating a group with space in group path' do
    it 'renders new group form with validation errors' do
      visit new_group_path
      fill_in 'Group path', with: 'space group'

      click_button 'Create group'

      expect(current_path).to eq(groups_path)
      expect(page).to have_content("Path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-' or end in '.'.")
    end
  end

  describe 'description' do
    let(:group) { create(:group) }
    let(:path)  { group_path(group) }

    it 'parses Markdown' do
      group.update_attribute(:description, 'This is **my** group')
      visit path
      expect(page).to have_css('.description > p > strong')
    end

    it 'passes through html-pipeline' do
      group.update_attribute(:description, 'This group is the :poop:')
      visit path
      expect(page).to have_css('.description > p > img')
    end

    it 'sanitizes unwanted tags' do
      group.update_attribute(:description, '# Group Description')
      visit path
      expect(page).not_to have_css('.description h1')
    end

    it 'permits `rel` attribute on links' do
      group.update_attribute(:description, 'https://google.com/')
      visit path
      expect(page).to have_css('.description a[rel]')
    end
  end
end
