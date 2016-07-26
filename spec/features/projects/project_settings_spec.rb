require 'spec_helper'

describe 'Edit Project Settings', feature: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, path: 'gitlab', name: 'sample') }

  before do
    login_as(user)
    project.team << [user, :master]
  end

  describe 'Project settings', js: true do
    it 'shows errors for invalid project name' do
      visit edit_namespace_project_path(project.namespace, project)

      fill_in 'project_name_edit', with: 'foo&bar'

      click_button 'Save changes'

      expect(page).to have_field 'project_name_edit', with: 'foo&bar'
      expect(page).to have_content "Name can contain only letters, digits, '_', '.', dash and space. It must start with letter, digit or '_'."
      expect(page).to have_button 'Save changes'
    end
  end

  describe 'Rename repository' do
    it 'shows errors for invalid project path/name' do
      visit edit_namespace_project_path(project.namespace, project)

      fill_in 'Project name', with: 'foo&bar'
      fill_in 'Path', with: 'foo&bar'

      click_button 'Rename project'

      expect(page).to have_field 'Project name', with: 'sample'
      expect(page).to have_field 'Path', with: 'gitlab'
      expect(page).to have_content "Name can contain only letters, digits, '_', '.', dash and space. It must start with letter, digit or '_'."
      expect(page).to have_content "Path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-', end in '.git' or end in '.atom'"
    end
  end
end
