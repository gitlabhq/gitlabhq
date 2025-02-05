# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User creates a directory', :js, feature_category: :source_code_management do
  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end

  let(:project) { create(:project, :repository) }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
    visit project_tree_path(project, 'master')

    wait_for_requests
  end

  context 'with default target branch' do
    before do
      first('.add-to-tree').click
      click_button('New directory')
    end

    it 'creates the directory in the default branch' do
      fill_in(:dir_name, with: 'new_directory')
      click_button('Commit changes')

      expect(page).to have_content('master')
      expect(page).to have_content('The directory has been successfully created')
      expect(page).to have_content('new_directory')
    end

    it 'does not create a directory with a name of already existed directory' do
      fill_in(:dir_name, with: 'files')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      expect(page).to have_content('Error creating new directory. Please try again.')
      expect(page).to have_current_path(project_tree_path(project, 'master'), ignore_query: true)
    end
  end

  context 'inside sub-folder' do
    it 'creates new directory' do
      click_link 'files'

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('files')
      end

      first('.add-to-tree').click
      click_button('New directory')

      fill_in(:dir_name, with: 'new_directory')
      click_button('Commit changes')

      expect(page).to have_content('files')
      expect(page).to have_content('new_directory')
    end
  end

  context 'with a new target branch' do
    before do
      first('.add-to-tree').click
      click_button('New directory')
      fill_in(:dir_name, with: 'new_directory')
      choose('Commit to a new branch', option: true)
      fill_in(:branch_name, with: 'new-feature')
    end

    context 'when create a merge request for changes is selected' do
      it 'creates the directory in the new branch and redirect to the merge request' do
        click_button('Commit changes')

        expect(page).to have_content('new-feature')
        expect(page).to have_content('The directory has been successfully created')
        expect(page).to have_content('New merge request')
        expect(page).to have_content('From new-feature into master')
        expect(page).to have_content('Add new directory')

        expect(page).to have_current_path(project_new_merge_request_path(project), ignore_query: true)
      end
    end

    context 'when create a merge request for changes is not selected' do
      it 'creates the directory in the new branch and redirect to that directory' do
        uncheck('Create a merge request for this change')
        click_button('Commit changes')

        expect(page).to have_content('The directory has been successfully created')
        expect(page).to have_content('new_directory')
        expect(page).to have_current_path(project_tree_path(project, File.join('new-feature', 'new_directory')),
          ignore_query: true)
      end
    end
  end

  context 'when an user does not have write access' do
    before do
      project2.add_reporter(user)
      visit(project2_tree_path_root_ref)
    end

    it 'creates a directory in a forked project', :sidekiq_might_not_need_inline do
      find('.add-to-tree').click
      click_link('New directory')

      expect(page).to have_content(fork_message)

      find('.add-to-tree').click
      wait_for_requests
      click_button('New directory')
      fill_in(:dir_name, with: 'new_directory')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      fork = user.fork_of(project2.reload)
      wait_for_requests

      expect(page).to have_current_path(project_new_merge_request_path(fork), ignore_query: true)
    end
  end
end
