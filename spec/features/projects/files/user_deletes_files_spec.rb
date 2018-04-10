require 'spec_helper'

describe 'Projects > Files > User deletes files' do
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
      project.add_master(user)
      visit(project_tree_path_root_ref)
    end

    it 'deletes the file', :js do
      click_link('.gitignore')

      expect(page).to have_content('.gitignore')

      click_on('Delete')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Delete file')

      expect(current_path).to eq(project_tree_path(project, 'master'))
      expect(page).not_to have_content('.gitignore')
    end
  end

  context 'when an user does not have write access' do
    before do
      project2.add_reporter(user)
      visit(project2_tree_path_root_ref)
    end

    it 'deletes the file in a forked project', :js do
      click_link('.gitignore')

      expect(page).to have_content('.gitignore')

      click_on('Delete')

      expect(page).to have_link('Fork')
      expect(page).to have_button('Cancel')

      click_link('Fork')

      expect(page).to have_content(fork_message)

      click_on('Delete')
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Delete file')

      fork = user.fork_of(project2.reload)

      expect(current_path).to eq(project_new_merge_request_path(fork))
      expect(page).to have_content('New commit message')
    end
  end
end
