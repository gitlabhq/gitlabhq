require 'spec_helper'

describe 'Projects > Files > User edits files' do
  include ProjectForksHelper
  let(:project) { create(:project, :repository, name: 'Shop') }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project_tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples 'unavailable for an archived project' do
    it 'does not show the edit link for an archived project', :js do
      project.update!(archived: true)
      visit project_tree_path(project, project.repository.root_ref)

      click_link('.gitignore')

      aggregate_failures 'available edit buttons' do
        expect(page).not_to have_text('Edit')
        expect(page).not_to have_text('Web IDE')

        expect(page).not_to have_text('Replace')
        expect(page).not_to have_text('Delete')
      end
    end
  end

  context 'when an user has write access' do
    before do
      project.add_master(user)
      visit(project_tree_path_root_ref)
    end

    it 'inserts a content of a file', :js do
      click_link('.gitignore')
      find('.js-edit-blob').click
      find('.file-editor', match: :first)

      find('#editor')
      execute_script("ace.edit('editor').setValue('*.rbca')")

      expect(evaluate_script('ace.edit("editor").getValue()')).to eq('*.rbca')
    end

    it 'does not show the edit link if a file is binary' do
      binary_file = File.join(project.repository.root_ref, 'files/images/logo-black.png')
      visit(project_blob_path(project, binary_file))

      page.within '.content' do
        expect(page).not_to have_link('edit')
      end
    end

    it 'commits an edited file', :js do
      click_link('.gitignore')
      find('.js-edit-blob').click
      find('.file-editor', match: :first)

      find('#editor')
      execute_script("ace.edit('editor').setValue('*.rbca')")
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      expect(current_path).to eq(project_blob_path(project, 'master/.gitignore'))

      wait_for_requests

      expect(page).to have_content('*.rbca')
    end

    it 'commits an edited file to a new branch', :js do
      click_link('.gitignore')
      find('.js-edit-blob').click

      find('.file-editor', match: :first)

      find('#editor')
      execute_script("ace.edit('editor').setValue('*.rbca')")
      fill_in(:commit_message, with: 'New commit message', visible: true)
      fill_in(:branch_name, with: 'new_branch_name', visible: true)
      click_button('Commit changes')

      expect(current_path).to eq(project_new_merge_request_path(project))

      click_link('Changes')

      expect(page).to have_content('*.rbca')
    end

    it 'shows the diff of an edited file', :js do
      click_link('.gitignore')
      find('.js-edit-blob').click
      find('.file-editor', match: :first)

      find('#editor')
      execute_script("ace.edit('editor').setValue('*.rbca')")
      click_link('Preview changes')

      expect(page).to have_css('.line_holder.new')
    end

    it_behaves_like 'unavailable for an archived project'
  end

  context 'when an user does not have write access' do
    before do
      project2.add_reporter(user)
      visit(project2_tree_path_root_ref)
    end

    it 'inserts a content of a file in a forked project', :js do
      click_link('.gitignore')
      find('.js-edit-blob').click

      expect(page).to have_link('Fork')
      expect(page).to have_button('Cancel')

      click_link('Fork')

      expect(page).to have_content(
        "You're not allowed to make changes to this project directly. "\
        "A fork of this project has been created that you can make changes in, so you can submit a merge request."
      )

      find('.file-editor', match: :first)

      find('#editor')
      execute_script("ace.edit('editor').setValue('*.rbca')")

      expect(evaluate_script('ace.edit("editor").getValue()')).to eq('*.rbca')
    end

    it 'commits an edited file in a forked project', :js do
      click_link('.gitignore')
      find('.js-edit-blob').click

      expect(page).to have_link('Fork')
      expect(page).to have_button('Cancel')

      click_link('Fork')

      find('.file-editor', match: :first)

      find('#editor')
      execute_script("ace.edit('editor').setValue('*.rbca')")
      fill_in(:commit_message, with: 'New commit message', visible: true)
      click_button('Commit changes')

      fork = user.fork_of(project2.reload)

      expect(current_path).to eq(project_new_merge_request_path(fork))

      wait_for_requests

      expect(page).to have_content('New commit message')
    end

    context 'when the user already had a fork of the project', :js do
      let!(:forked_project) { fork_project(project2, user, namespace: user.namespace, repository: true) }
      before do
        visit(project2_tree_path_root_ref)
      end

      it 'links to the forked project for editing' do
        click_link('.gitignore')
        find('.js-edit-blob').click

        expect(page).not_to have_link('Fork')
        expect(page).not_to have_button('Cancel')

        find('#editor')
        execute_script("ace.edit('editor').setValue('*.rbca')")
        fill_in(:commit_message, with: 'Another commit', visible: true)
        click_button('Commit changes')

        fork = user.fork_of(project2)

        expect(current_path).to eq(project_new_merge_request_path(fork))

        wait_for_requests

        expect(page).to have_content('Another commit')
        expect(page).to have_content("From #{forked_project.full_path}")
        expect(page).to have_content("into #{project2.full_path}")
      end

      it_behaves_like 'unavailable for an archived project' do
        let(:project) { project2 }
      end
    end
  end
end
