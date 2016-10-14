require 'spec_helper'

feature 'Group', feature: true do
  before do
    login_as(:admin)
  end

  matcher :have_namespace_error_message do
    match do |page|
      page.has_content?("Path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-' or end in '.', '.git' or '.atom'.")
    end
  end

  describe 'create a group' do
    before { visit new_group_path }

    describe 'with space in group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group path', with: 'space group'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end

    describe 'with .atom at end of group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group path', with: 'atom_group.atom'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end

    describe 'with .git at end of group path' do
      it 'renders new group form with validation errors' do
        fill_in 'Group path', with: 'git_group.git'
        click_button 'Create group'

        expect(current_path).to eq(groups_path)
        expect(page).to have_namespace_error_message
      end
    end
  end

  describe 'group edit' do
    let(:group) { create(:group) }
    let(:path)  { edit_group_path(group) }
    let(:new_name) { 'new-name' }

    before { visit path }

    it 'saves new settings' do
      fill_in 'group_name', with: new_name
      click_button 'Save group'

      expect(page).to have_content 'successfully updated'
      expect(find('#group_name').value).to eq(new_name)

      page.within ".navbar-gitlab" do
        expect(page).to have_content new_name
      end
    end

    it 'removes group' do
      click_link 'Remove Group'

      expect(page).to have_content "scheduled for deletion"
    end
  end

  describe 'group page with markdown description' do
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
