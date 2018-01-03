require 'spec_helper'

describe 'User browses files' do
  include DropzoneHelper

  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end
  let(:project) { create(:project, :repository, name: 'Shop') }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let(:tree_path_ref_6d39438) { project_tree_path(project, '6d39438') }
  let(:tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  context 'when browsing the master branch' do
    before do
      visit(tree_path_root_ref)
    end

    it 'shows files from a repository' do
      expect(page).to have_content('VERSION')
      expect(page).to have_content('.gitignore')
      expect(page).to have_content('LICENSE')
    end

    it 'shows the "Browse Directory" link' do
      click_link('files')
      click_link('History')

      expect(page).to have_link('Browse Directory')
      expect(page).not_to have_link('Browse Code')
    end

    it 'shows the "Browse File" link' do
      page.within('.tree-table') do
        click_link('README.md')
      end
      click_link('History')

      expect(page).to have_link('Browse File')
      expect(page).not_to have_link('Browse Files')
    end

    it 'shows the "Browse Code" link' do
      click_link('History')

      expect(page).to have_link('Browse Files')
      expect(page).not_to have_link('Browse Directory')
    end

    it 'redirects to the permalink URL' do
      click_link('.gitignore')
      click_link('Permalink')

      permalink_path = project_blob_path(project, "#{project.repository.commit.sha}/.gitignore")

      expect(current_path).to eq(permalink_path)
    end
  end

  context 'when browsing a specific ref' do
    before do
      visit(tree_path_ref_6d39438)
    end

    it 'shows files from a repository for "6d39438"' do
      expect(current_path).to eq(tree_path_ref_6d39438)
      expect(page).to have_content('.gitignore')
      expect(page).to have_content('LICENSE')
    end

    it 'shows files from a repository with apostroph in its name', :js do
      first('.js-project-refs-dropdown').click

      page.within('.project-refs-form') do
        click_link("'test'")
      end

      expect(page).to have_selector('.dropdown-toggle-text', text: "'test'")

      visit(project_tree_path(project, "'test'"))

      expect(page).to have_css('.tree-commit-link', visible: true)
      expect(page).not_to have_content('Loading commit data...')
    end

    it 'shows the code with a leading dot in the directory', :js do
      first('.js-project-refs-dropdown').click

      page.within('.project-refs-form') do
        click_link('fix')
      end

      visit(project_tree_path(project, 'fix/.testdir'))

      expect(page).to have_css('.tree-commit-link', visible: true)
      expect(page).not_to have_content('Loading commit data...')
    end

    it 'does not show the permalink link' do
      click_link('.gitignore')

      expect(page).not_to have_link('permalink')
    end
  end

  context 'when browsing a file content' do
    before do
      visit(tree_path_root_ref)
      click_link('.gitignore')
    end

    it 'shows a file content', :js do
      wait_for_requests
      expect(page).to have_content('*.rbc')
    end
  end

  context 'when browsing a raw file' do
    before do
      visit(project_blob_path(project, File.join(RepoHelpers.sample_commit.id, RepoHelpers.sample_blob.path)))
    end

    it 'shows a raw file content' do
      click_link('Open raw')
      expect(source).to eq('') # Body is filled in by gitlab-workhorse
    end
  end

  context 'when browsing an LFS object' do
    before do
      allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(true)
      visit(project_tree_path(project, 'lfs'))
    end

    it 'shows an LFS object' do
      click_link('files')
      click_link('lfs')
      click_link('lfs_object.iso')

      expect(page).to have_content('Download (1.5 MB)')
      expect(page).not_to have_content('version https://git-lfs.github.com/spec/v1')
      expect(page).not_to have_content('oid sha256:91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897')
      expect(page).not_to have_content('size 1575078')

      page.within('.content') do
        expect(page).to have_content('Delete')
        expect(page).to have_content('History')
        expect(page).to have_content('Permalink')
        expect(page).to have_content('Replace')
        expect(page).not_to have_content('Annotate')
        expect(page).not_to have_content('Blame')
        expect(page).not_to have_content('Edit')
        expect(page).to have_link('Download')
      end
    end
  end

  context 'when previewing a file content' do
    before do
      visit(tree_path_root_ref)
    end

    it 'shows a preview of a file content', :js do
      find('.add-to-tree').click
      click_link('Upload file')
      drop_in_dropzone(File.join(Rails.root, 'spec', 'fixtures', 'logo_sample.svg'))

      page.within('#modal-upload-blob') do
        fill_in(:commit_message, with: 'New commit message')
        fill_in(:branch_name, with: 'new_branch_name', visible: true)
        click_button('Upload file')
      end

      wait_for_all_requests

      visit(project_blob_path(project, 'new_branch_name/logo_sample.svg'))

      expect(page).to have_css('.file-content img')
    end
  end
end
