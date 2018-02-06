require 'spec_helper'

feature 'Master updates tag' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    project.add_master(user)
    sign_in(user)
    visit project_tags_path(project)
  end

  context 'from the tags list page' do
    scenario 'updates the release notes' do
      page.within(first('.content-list .controls')) do
        click_link 'Edit release notes'
      end

      fill_in 'release_description', with: 'Awesome release notes'
      click_button 'Save changes'

      expect(current_path).to eq(
        project_tag_path(project, 'v1.1.0'))
      expect(page).to have_content 'v1.1.0'
      expect(page).to have_content 'Awesome release notes'
    end

    scenario 'description has autocomplete', :js do
      page.within(first('.content-list .controls')) do
        click_link 'Edit release notes'
      end

      find('#release_description').native.send_keys('')
      fill_in 'release_description', with: '@'

      expect(page).to have_selector('.atwho-view')
    end
  end

  context 'from a specific tag page' do
    scenario 'updates the release notes' do
      click_on 'v1.1.0'
      click_link 'Edit release notes'
      fill_in 'release_description', with: 'Awesome release notes'
      click_button 'Save changes'

      expect(current_path).to eq(
        project_tag_path(project, 'v1.1.0'))
      expect(page).to have_content 'v1.1.0'
      expect(page).to have_content 'Awesome release notes'
    end
  end
end
