require 'spec_helper'

feature 'New blob creation', feature: true, js: true do
  include TargetBranchHelpers

  given(:user) { create(:user) }
  given(:role) { :developer }
  given(:project) { create(:project) }
  given(:content) { 'class NextFeature\nend\n' }

  background do
    login_as(user)
    project.team << [user, role]
    visit namespace_project_new_blob_path(project.namespace, project, 'master')
  end

  def edit_file
    wait_for_ajax
    fill_in 'file_name', with: 'feature.rb'
    execute_script("ace.edit('editor').setValue('#{content}')")
  end

  def commit_file
    click_button 'Commit changes'
  end

  context 'with default target branch' do
    background do
      edit_file
      commit_file
    end

    scenario 'creates the blob in the default branch' do
      expect(page).to have_content 'master'
      expect(page).to have_content 'successfully created'
      expect(page).to have_content 'NextFeature'
    end
  end

  context 'with different target branch' do
    background do
      edit_file
      select_branch('feature')
      commit_file
    end

    scenario 'creates the blob in the different branch' do
      expect(page).to have_content 'feature'
      expect(page).to have_content 'successfully created'
    end
  end

  context 'with a new target branch' do
    given(:new_branch_name) { 'new-feature' }

    background do
      edit_file
      create_new_branch(new_branch_name)
      commit_file
    end

    scenario 'creates the blob in the new branch' do
      expect(page).to have_content new_branch_name
      expect(page).to have_content 'successfully created'
    end
    scenario 'returns you to the mr' do
      expect(page).to have_content 'New Merge Request'
      expect(page).to have_content "From #{new_branch_name} into master"
      expect(page).to have_content 'Add new file'
    end
  end

  context 'the file already exist in the source branch' do
    background do
      Files::CreateService.new(
        project,
        user,
        start_branch: 'master',
        branch_name: 'master',
        commit_message: 'Create file',
        file_path: 'feature.rb',
        file_content: content
      ).execute
      edit_file
      commit_file
    end

    scenario 'shows error message' do
      expect(page).to have_content('A file with this name already exists')
      expect(page).to have_content('New file')
      expect(page).to have_content('NextFeature')
    end
  end
end
