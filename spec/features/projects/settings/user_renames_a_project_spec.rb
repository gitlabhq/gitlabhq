require 'spec_helper'

describe 'Projects > Settings > User renames a project' do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace, path: 'gitlab', name: 'sample') }

  before do
    sign_in(user)
    visit edit_project_path(project)
  end

  def rename_project(project, name: nil, path: nil)
    fill_in('project_name', with: name) if name
    fill_in('Path', with: path) if path
    click_button('Rename project')
    wait_for_edit_project_page_reload
    project.reload
  end

  def wait_for_edit_project_page_reload
    expect(find('.project-edit-container')).to have_content('Rename repository')
  end

  context 'with invalid characters' do
    it 'shows errors for invalid project path/name' do
      rename_project(project, name: 'foo&bar', path: 'foo&bar')
      expect(page).to have_field 'Project name', with: 'foo&bar'
      expect(page).to have_field 'Path', with: 'foo&bar'
      expect(page).to have_content "Name can contain only letters, digits, emojis, '_', '.', dash, space. It must start with letter, digit, emoji or '_'."
      expect(page).to have_content "Path can contain only letters, digits, '_', '-' and '.'. Cannot start with '-', end in '.git' or end in '.atom'"
    end
  end

  it 'shows a successful notice when the project is updated' do
    fill_in 'project_name_edit', with: 'hello world'
    page.within('.general-settings') do
      click_button 'Save changes'
    end

    expect(page).to have_content "Project 'hello world' was successfully updated."
  end

  context 'when changing project name' do
    it 'renames the repository' do
      rename_project(project, name: 'bar')
      expect(find('.breadcrumbs')).to have_content(project.name)
    end

    context 'with emojis' do
      it 'shows error for invalid project name' do
        rename_project(project, name: '🚀 foo bar ☁️')
        expect(page).to have_field 'Project name', with: '🚀 foo bar ☁️'
        expect(page).not_to have_content "Name can contain only letters, digits, emojis '_', '.', dash and space. It must start with letter, digit, emoji or '_'."
      end
    end
  end

  context 'when changing project path' do
    let(:project) { create(:project, :repository, namespace: user.namespace, name: 'gitlabhq') }

    before(:context) do
      TestEnv.clean_test_path
    end

    after do
      TestEnv.clean_test_path
    end

    it 'the project is accessible via the new path' do
      rename_project(project, path: 'bar')
      new_path = namespace_project_path(project.namespace, 'bar')
      visit new_path

      expect(current_path).to eq(new_path)
      expect(find('.breadcrumbs')).to have_content(project.name)
    end

    it 'the project is accessible via a redirect from the old path' do
      old_path = project_path(project)
      rename_project(project, path: 'bar')
      new_path = namespace_project_path(project.namespace, 'bar')
      visit old_path

      expect(current_path).to eq(new_path)
      expect(find('.breadcrumbs')).to have_content(project.name)
    end

    context 'and a new project is added with the same path' do
      it 'overrides the redirect' do
        old_path = project_path(project)
        rename_project(project, path: 'bar')
        new_project = create(:project, namespace: user.namespace, path: 'gitlabhq', name: 'quz')
        visit old_path

        expect(current_path).to eq(old_path)
        expect(find('.breadcrumbs')).to have_content(new_project.name)
      end
    end
  end
end
