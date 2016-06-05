require 'spec_helper'

feature 'Master updates tag', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    project.team << [user, :master]
    login_with(user)
    visit namespace_project_tags_path(project.namespace, project)
  end

  context 'from the tags list page' do
    scenario 'updates the release notes' do
      page.within(first('.content-list .controls')) do
        click_link 'Edit release notes'
      end

      fill_in 'release_description', with: 'Awesome release notes'
      click_button 'Save changes'

      expect(current_path).to eq(
        namespace_project_tag_path(project.namespace, project, 'v1.1.0'))
      expect(page).to have_content 'v1.1.0'
      expect(page).to have_content 'Awesome release notes'
    end
  end

  context 'from a specific tag page' do
    scenario 'updates the release notes' do
      click_on 'v1.1.0'
      click_link 'Edit release notes'
      fill_in 'release_description', with: 'Awesome release notes'
      click_button 'Save changes'

      expect(current_path).to eq(
        namespace_project_tag_path(project.namespace, project, 'v1.1.0'))
      expect(page).to have_content 'v1.1.0'
      expect(page).to have_content 'Awesome release notes'
    end
  end
end
