# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Files > User creates a directory', :js do
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
  end

  context 'with default target branch' do
    before do
      first('.add-to-tree').click
      click_link('New directory')
    end

    it 'creates the directory in the default branch' do
      fill_in(:dir_name, with: 'new_directory')
      click_button('Create directory')

      expect(page).to have_content('master')
      expect(page).to have_content('The directory has been successfully created')
      expect(page).to have_content('new_directory')
    end

    it 'does not create a directory with a name of already existed directory' do
      fill_in(:dir_name, with: 'files')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Create directory')

      expect(page).to have_content('A directory with this name already exists')
      expect(current_path).to eq(project_tree_path(project, 'master'))
    end
  end

  context 'with a new target branch' do
    before do
      first('.add-to-tree').click
      click_link('New directory')
      fill_in(:dir_name, with: 'new_directory')
      fill_in(:branch_name, with: 'new-feature')
      click_button('Create directory')
    end

    it 'creates the directory in the new branch and redirect to the merge request' do
      expect(page).to have_content('new-feature')
      expect(page).to have_content('The directory has been successfully created')
      expect(page).to have_content('New Merge Request')
      expect(page).to have_content('From new-feature into master')
      expect(page).to have_content('Add new directory')

      expect(current_path).to eq(project_new_merge_request_path(project))
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
      click_link('New directory')
      fill_in(:dir_name, with: 'new_directory')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Create directory')

      fork = user.fork_of(project2.reload)

      expect(current_path).to eq(project_new_merge_request_path(fork))
    end
  end
end
