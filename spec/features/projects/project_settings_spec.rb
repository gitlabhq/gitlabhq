require 'spec_helper'

describe 'Edit Project Settings', feature: true do
  include WaitForAjax

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
      expect(page).to have_content "Name can contain only letters, digits, emojis, '_', '.', dash, space. It must start with letter, digit, emoji or '_'."
      expect(page).to have_button 'Save changes'
    end

    it 'adds approver group' do
      group = create :group
      approver = create :user
      group.add_developer(approver)
      group.add_developer(user)

      visit edit_namespace_project_path(project.namespace, project)

      find('#s2id_project_approver_group_ids .select2-input').click

      wait_for_ajax

      expect(find('.select2-results')).to have_content(group.name)

      find('.select2-results').click

      click_button 'Save changes'

      expect(page).to have_css('.approver-list li.approver-group', count: 1)
    end

    it 'removes approver group' do
      group = create :group
      approver = create :user
      group.add_developer(approver)
      group.add_developer(user)
      create :approver_group, group: group, target: project

      visit edit_namespace_project_path(project.namespace, project)

      expect(find('.approver-list')).to have_content(group.name)

      within('.approver-list') do
        click_on "Remove"
      end

      expect(find('.approver-list')).not_to have_content(group.name)
    end
  end

  describe 'Rename repository' do
    it 'shows errors for invalid project path/name' do
      visit edit_namespace_project_path(project.namespace, project)

      fill_in 'Project name', with: 'foo&bar'
      fill_in 'Path', with: 'foo&bar'

      click_button 'Rename project'

      expect(page).to have_field 'Project name', with: 'foo&bar'
      expect(page).to have_field 'Path', with: 'foo&bar'
      expect(page).to have_content "Name can contain only letters, digits, emojis, '_', '.', dash, space. It must start with letter, digit, emoji or '_'."
      expect(page).to have_content "Path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-', end in '.git' or end in '.atom'"
    end
  end

  describe 'Rename repository name with emojis' do
    it 'shows error for invalid project name' do
      visit edit_namespace_project_path(project.namespace, project)

      fill_in 'Project name', with: '🚀 foo bar ☁️'

      click_button 'Rename project'

      expect(page).to have_field 'Project name', with: '🚀 foo bar ☁️'
      expect(page).not_to have_content "Name can contain only letters, digits, emojis '_', '.', dash and space. It must start with letter, digit, emoji or '_'."
    end
  end
end
