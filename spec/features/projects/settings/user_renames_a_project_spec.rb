# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User renames a project', feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace, path: 'gitlab', name: 'sample') }

  before do
    sign_in(user)
    visit edit_project_path(project)
  end

  def change_path(path)
    within_testid('advanced-settings-content') do
      fill_in('Path', with: path)
      click_button('Change path')
    end
    wait_for_edit_project_page_reload
  end

  def wait_for_edit_project_page_reload
    expect(find_by_testid('advanced-settings-content')).to have_content('Change path')
  end

  def change_name(name)
    within_testid('general-settings-content') do
      fill_in('Project name', with: name)
      click_button('Save changes')
    end
    wait_for_edit_project_page_reload
  end

  def expect_current_path(path)
    expect(page).to have_current_path(path, ignore_query: true)
  end

  def expect_name_in_breadcrumb(name)
    expect(find_by_testid('breadcrumb-links')).to have_content(name)
  end

  context 'with invalid characters' do
    it 'shows errors for invalid project path' do
      change_path('foo&bar')

      expect(page).to have_field 'Path', with: project.path
      expect(page).to have_content "Path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-', end in '.git' or end in '.atom'"
    end
  end

  context 'when changing project name', :js do
    it 'renames the repository' do
      new_name = '🧮 foo bar ☁️'

      change_name(new_name)

      expect(page).to have_field 'Project name', with: new_name
      expect(page).to have_content "Project '#{new_name}' was successfully updated."
      expect_name_in_breadcrumb(new_name)
    end
  end

  context 'when changing project path', :js do
    let(:project) { create(:project, :repository, namespace: user.namespace, path: 'gitlabhq') }

    before(:context) do
      TestEnv.clean_test_path
    end

    after do
      TestEnv.clean_test_path
    end

    it 'the project is accessible via the new path' do
      new_path = 'bar'
      change_path(new_path)
      new_full_path = namespace_project_path(project.namespace, new_path)
      visit new_full_path

      expect_current_path(new_full_path)
      expect(find_by_testid('breadcrumb-links')).to have_content(project.name)
    end

    it 'the project is accessible via a redirect from the old path' do
      old_path = project_path(project)
      new_path = 'bar'
      change_path('bar')

      visit old_path

      expect_current_path(namespace_project_path(project.namespace, new_path))
      expect_name_in_breadcrumb(project.name)
    end

    context 'and a new project is added with the same path' do
      it 'overrides the redirect' do
        old_path = project_path(project)
        change_path('bar')

        new_project = create(:project, namespace: user.namespace, path: 'gitlabhq', name: 'quz')

        visit old_path

        expect_current_path(old_path)
        expect_name_in_breadcrumb(new_project.name)
      end
    end
  end
end
