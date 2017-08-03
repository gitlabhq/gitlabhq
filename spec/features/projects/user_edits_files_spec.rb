require 'spec_helper'

describe 'User edits files' do
  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end
  let(:project) { create(:project, :repository, name: 'Shop') }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project_tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when an user has write access' do
    before do
      project.team << [user, :master]
      visit(project_tree_path_root_ref)
    end

    it 'inserts a content of a file', js: true do
      click_link('.gitignore')
      find('.js-edit-blob').click
      execute_script("ace.edit('editor').setValue('*.rbca')")

      expect(evaluate_script('ace.edit("editor").getValue()')).to eq('*.rbca')
    end

    it 'does not show the edit link if a file is binary' do
      binary_file = File.join(project.repository.root_ref, 'files/images/logo-black.png')
      visit(project_blob_path(project, binary_file))

      expect(page).not_to have_link('edit')
    end

    it 'commits an edited file', js: true do
      click_link('.gitignore')
      find('.js-edit-blob').click
      execute_script("ace.edit('editor').setValue('*.rbca')")
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      expect(current_path).to eq(project_blob_path(project, 'master/.gitignore'))

      wait_for_requests

      expect(page).to have_content('*.rbca')
    end

    it 'commits an edited file to a new branch', js: true do
      click_link('.gitignore')
      find('.js-edit-blob').click
      execute_script("ace.edit('editor').setValue('*.rbca')")
      fill_in(:commit_message, with: 'New commit message', visible: true)
      fill_in(:branch_name, with: 'new_branch_name', visible: true)
      click_button('Commit changes')

      expect(current_path).to eq(project_new_merge_request_path(project))

      click_link('Changes')

      wait_for_requests
      expect(page).to have_content('*.rbca')
    end

    it 'shows the diff of an edited file', js: true do
      click_link('.gitignore')
      find('.js-edit-blob').click
      execute_script("ace.edit('editor').setValue('*.rbca')")
      click_link('Preview changes')

      expect(page).to have_css('.line_holder.new')
    end
  end

  context 'when an user does not have write access' do
    before do
      project2.team << [user, :reporter]
      visit(project2_tree_path_root_ref)
    end

    it 'inserts a content of a file in a forked project', js: true do
      click_link('.gitignore')
      find('.js-edit-blob').click

      expect(page).to have_link('Fork')
      expect(page).to have_button('Cancel')

      click_link('Fork')

      expect(page).to have_content(fork_message)

      execute_script("ace.edit('editor').setValue('*.rbca')")

      expect(evaluate_script('ace.edit("editor").getValue()')).to eq('*.rbca')
    end

    it 'commits an edited file in a forked project', js: true do
      click_link('.gitignore')
      find('.js-edit-blob').click

      expect(page).to have_link('Fork')
      expect(page).to have_button('Cancel')

      click_link('Fork')
      execute_script("ace.edit('editor').setValue('*.rbca')")
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      fork = user.fork_of(project2)

      expect(current_path).to eq(project_new_merge_request_path(fork))

      wait_for_requests

      expect(page).to have_content('New commit message')
    end
  end
end
