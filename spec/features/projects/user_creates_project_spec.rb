# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates a project', :js, feature_category: :groups_and_projects do
  include ListboxHelpers

  let(:user) { create(:user) }

  before do
    stub_feature_flags(new_project_creation_form: false)
    sign_in(user)
    create(:personal_key, user: user)
  end

  it 'creates a new project' do
    visit(new_project_path)

    click_link 'Create blank project'
    fill_in(:project_name, with: 'Empty')

    expect(page).to have_checked_field 'Initialize repository with a README'
    uncheck 'Initialize repository with a README'

    page.within('#content-body') do
      click_button('Create project')
    end

    project = Project.last

    expect(page).to have_current_path(project_path(project), ignore_query: true)
    expect(page).to have_content('Empty')
    expect(page).to have_content('git init')
    expect(page).to have_content('git remote')
    expect(page).to have_content(project.url_to_repo)
  end

  it 'creates a new project that is not blank' do
    visit(new_project_path)

    click_link 'Create blank project'
    fill_in(:project_name, with: 'With initial commits')

    expect(page).to have_checked_field 'Initialize repository with a README'
    expect(page).to have_unchecked_field 'Enable Static Application Security Testing (SAST)'

    check 'Enable Static Application Security Testing (SAST)'

    page.within('#content-body') do
      click_button('Create project')
    end

    project = Project.last

    expect(page).to have_current_path(project_path(project), ignore_query: true)
    expect(page).to have_content('With initial commits')
    expect(page).to have_content('Configure SAST in `.gitlab-ci.yml`, creating this file if it does not already exist')
    expect(page).to have_content('README.md Initial commit')
  end

  context 'when creating a project with SHA256 repository' do
    let(:sha256_field) { 'Use SHA-256 for repository hashing algorithm' }

    it 'creates a new project' do
      visit(new_project_path)

      click_link 'Create blank project'
      click_button 'Experimental settings'
      fill_in(:project_name, with: 'With initial commits')

      expect(page).to have_checked_field 'Initialize repository with a README'
      expect(page).to have_unchecked_field sha256_field

      check sha256_field

      page.within('#content-body') do
        click_button('Create project')
      end

      project = Project.last

      expect(page).to have_current_path(project_path(project), ignore_query: true)
      expect(page).to have_content('With initial commits')
    end

    context 'when "support_sha256_repositories" feature flag is disabled' do
      before do
        stub_feature_flags(support_sha256_repositories: false)
      end

      it 'does not display a SHA256 option' do
        visit(new_project_path)

        click_link 'Create blank project'

        expect(page).not_to have_content(sha256_field)
      end
    end
  end

  context 'in a subgroup they do not own' do
    let(:parent) { create(:group) }
    let!(:subgroup) { create(:group, parent: parent) }

    before do
      parent.add_owner(user)
    end

    it 'creates a new project' do
      visit(new_project_path)

      click_link 'Create blank project'
      fill_in :project_name, with: 'A Subgroup Project'
      fill_in :project_path, with: 'a-subgroup-project'

      click_on 'Pick a group or namespace'
      select_listbox_item subgroup.full_path

      click_button('Create project')

      expect(page).to have_content("Project 'A Subgroup Project' was successfully created")

      project = Project.last

      expect(project.namespace).to eq(subgroup)
    end
  end

  context 'in a group with DEVELOPER_MAINTAINER_PROJECT_ACCESS project_creation_level' do
    let(:group) { create(:group, project_creation_level: ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }

    before do
      group.add_developer(user)
    end

    it 'creates a new project' do
      visit(new_project_path)

      click_link 'Create blank project'
      fill_in :project_name, with: 'a-new-project'
      fill_in :project_path, with: 'a-new-project'

      page.within('#content-body') do
        click_button('Create project')
      end

      expect(page).to have_content("Project 'a-new-project' was successfully created")

      project = Project.find_by(name: 'a-new-project')
      expect(project.namespace).to eq(group)
    end
  end
end
