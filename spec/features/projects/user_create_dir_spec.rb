require 'spec_helper'

feature 'New directory creation', feature: true, js: true do
  include TargetBranchHelpers

  given(:user) { create(:user) }
  given(:role) { :developer }
  given(:project) { create(:project) }

  background do
    login_as(user)
    project.team << [user, role]
    visit namespace_project_tree_path(project.namespace, project, 'master')
    open_new_directory_modal
    fill_in 'dir_name', with: 'new_directory'
  end

  def open_new_directory_modal
    first('.add-to-tree').click
    click_link 'New directory'
  end

  def create_directory
    click_button 'Create directory'
  end

  context 'with default target branch' do
    background do
      create_directory
    end

    scenario 'creates the directory in the default branch' do
      expect(page).to have_content 'master'
      expect(page).to have_content 'The directory has been successfully created'
      expect(page).to have_content 'new_directory'
    end
  end

  context 'with different target branch' do
    background do
      select_branch('feature')
      create_directory
    end

    scenario 'creates the directory in the different branch' do
      expect(page).to have_content 'feature'
      expect(page).to have_content 'The directory has been successfully created'
    end
  end

  context 'with a new target branch' do
    given(:new_branch_name) { 'new-feature' }

    background do
      create_new_branch(new_branch_name)
      create_directory
    end

    scenario 'creates the directory in the new branch' do
      expect(page).to have_content new_branch_name
      expect(page).to have_content 'The directory has been successfully created'
    end

    scenario 'redirects to the merge request' do
      expect(page).to have_content 'New Merge Request'
      expect(page).to have_content "From #{new_branch_name} into master"
      expect(page).to have_content 'Add new directory'
      expect(current_path).to eq(new_namespace_project_merge_request_path(project.namespace, project))
    end
  end
end
