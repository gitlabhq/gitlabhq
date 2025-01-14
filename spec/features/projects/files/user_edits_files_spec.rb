# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Files > User edits files', :js, feature_category: :source_code_management do
  include Features::SourceEditorSpecHelpers
  include ProjectForksHelper
  include Features::BlobSpecHelpers
  include TreeHelper

  let_it_be(:json_text) { '{"name":"Best package ever!"}' }
  let_it_be(:project_with_json) { create(:project, :custom_repo, name: 'Project with json', files: { 'package.json' => json_text }) }
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :repository, name: 'Shop') }
  let(:project2) { create(:project, :repository, name: 'Another Project', path: 'another-project') }
  let(:project_tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:project2_tree_path_root_ref) { project_tree_path(project2, project2.repository.root_ref) }

  let_it_be(:lf_text) { 'Line 1\nLine 2\nLine 3\n' }
  let_it_be(:crlf_text) { 'Line 1\r\nLine 2\r\nLine 3\r\n"' }
  let_it_be(:project_with_lf) { create(:project, :custom_repo, name: 'Project with lf', files: { 'lf_file.txt' => lf_text }) }
  let_it_be(:project_with_crlf) { create(:project, :custom_repo, name: 'Project with crlf', files: { 'crlf_file.txt' => crlf_text }) }

  before do
    stub_feature_flags(vscode_web_ide: false)

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

  context 'when an user has write access', :js do
    before do
      project.add_maintainer(user)
      visit(project_tree_path_root_ref)
      wait_for_requests
    end

    it 'inserts a content of a file' do
      click_link('.gitignore')
      edit_in_single_file_editor
      find('.file-editor', match: :first)

      editor_set_value('*.rbca')

      expect(find('.monaco-editor')).to have_content('*.rbca')
    end

    it 'shows ref instead of full path when editing a file' do
      click_link('.gitignore')
      edit_in_single_file_editor

      expect(page).not_to have_selector('#editor_path')
      expect(page).to have_selector('#editor_ref')
    end

    it 'does not show the edit link if a file is binary' do
      binary_file = File.join(project.repository.root_ref, 'files/images/logo-black.png')
      visit(project_blob_path(project, binary_file))
      wait_for_requests

      page.within '.content' do
        expect(page).not_to have_link('edit')
      end
    end

    it 'commits an edited file' do
      click_link('.gitignore')
      edit_in_single_file_editor
      find('.file-editor', match: :first)

      editor_set_value('*.rbca')
      click_button('Commit changes')

      within_testid('commit-change-modal') do
        fill_in(:commit_message, with: 'New commit message', visible: true)
        click_button('Commit changes')
      end

      expect(page).to have_current_path(project_blob_path(project, 'master/.gitignore'), ignore_query: true)

      wait_for_requests

      expect(page).to have_content('*.rbca')
    end

    it 'displays a flash message with a link when an edited file was committed' do
      click_link('.gitignore')
      edit_in_single_file_editor
      find('.file-editor', match: :first)

      editor_set_value('*.rbca')
      click_button('Commit changes')

      within_testid('commit-change-modal') do
        fill_in(:commit_message, with: 'New commit message', visible: true)
        click_button('Commit changes')
      end

      expect(page).to have_current_path(project_blob_path(project, 'master/.gitignore'), ignore_query: true)

      wait_for_requests

      expect(page).to have_content('Your changes have been committed successfully')
      page.within '.flash-container' do
        expect(page).to have_link 'changes'
      end
    end

    it 'commits an edited file to a new branch' do
      click_link('.gitignore')
      edit_in_single_file_editor

      find('.file-editor', match: :first)

      editor_set_value('*.rbca')
      click_button('Commit changes')

      within_testid('commit-change-modal') do
        fill_in(:commit_message, with: 'New commit message', visible: true)
        choose(option: true)
        fill_in(:branch_name, with: 'new_branch_name', visible: true)
        click_button('Commit changes')
      end
      expect(page).to have_current_path(project_new_merge_request_path(project), ignore_query: true)

      click_link('Changes')

      expect(page).to have_content('*.rbca')
    end

    it 'shows the diff of an edited file' do
      click_link('.gitignore')
      edit_in_single_file_editor
      find('.file-editor', match: :first)

      editor_set_value('*.rbca')
      click_link('Preview changes')

      expect(page).to have_css('.line_holder.new')
    end

    it_behaves_like 'unavailable for an archived project'
  end

  context 'when an user does not have write access', :js do
    before do
      project2.add_reporter(user)
      visit(project2_tree_path_root_ref)
      wait_for_requests
    end

    def expect_fork_prompt
      expect(page).to have_selector(:link_or_button, 'Fork')
      expect(page).to have_selector(:link_or_button, 'Cancel')
      expect(page).to have_content(
        "You can’t edit files directly in this project. "\
        "Fork this project and submit a merge request with your changes."
      )
    end

    def expect_fork_status
      expect(page).to have_content(
        "You're not allowed to make changes to this project directly. "\
        "A fork of this project has been created that you can make changes in, so you can submit a merge request."
      )
    end

    it 'inserts a content of a file in a forked project', :sidekiq_might_not_need_inline do
      click_link('.gitignore')
      edit_in_single_file_editor

      expect_fork_prompt

      click_link_or_button('Fork')

      expect_fork_status

      find('.file-editor', match: :first)

      editor_set_value('*.rbca')

      expect(find('.monaco-editor')).to have_content('*.rbca')
    end

    it 'opens the Web IDE in a forked project', :sidekiq_might_not_need_inline do
      click_link('.gitignore')
      edit_in_web_ide

      expect_fork_prompt

      click_link_or_button('Fork')

      expect_fork_status

      expect(page).to have_css('.ide-sidebar-project-title', text: "#{project2.name} #{user.namespace.full_path}/#{project2.path}")
      expect(page).to have_css('.ide .multi-file-tab', text: '.gitignore')
    end

    it 'commits an edited file in a forked project', :sidekiq_might_not_need_inline do
      click_link('.gitignore')
      edit_in_single_file_editor

      expect_fork_prompt
      click_link_or_button('Fork')

      find('.file-editor', match: :first)

      editor_set_value('*.rbca')
      click_button('Commit changes')

      within_testid('commit-change-modal') do
        fill_in(:commit_message, with: 'New commit message', visible: true)
        click_button('Commit changes')
      end

      fork = user.fork_of(project2.reload)

      expect(page).to have_current_path(project_new_merge_request_path(fork), ignore_query: true)

      wait_for_requests

      expect(page).to have_content('New commit message')
    end

    context 'when the user already had a fork of the project', :js do
      let!(:forked_project) { fork_project(project2, user, namespace: user.namespace, repository: true) }

      before do
        visit(project2_tree_path_root_ref)
        wait_for_requests
      end

      it 'links to the forked project for editing', :sidekiq_might_not_need_inline do
        click_link('.gitignore')
        edit_in_single_file_editor

        expect(page).not_to have_link('Fork')

        editor_set_value('*.rbca')
        click_button('Commit changes')

        within_testid('commit-change-modal') do
          fill_in(:commit_message, with: 'Another commit', visible: true)
          click_button('Commit changes')
        end

        fork = user.fork_of(project2)

        expect(page).to have_current_path(project_new_merge_request_path(fork), ignore_query: true)

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

  context 'when editing a json file', :js do
    before_all do
      project_with_json.add_maintainer(user)
    end

    it 'loads the content as text' do
      visit(project_edit_blob_path(project_with_json, tree_join(project_with_json.default_branch, 'package.json')))
      wait_for_requests
      expect(find('.monaco-editor')).to have_content(json_text)
    end
  end

  context 'for line endings', :js do
    before_all do
      project_with_lf.add_maintainer(user)
      project_with_crlf.add_maintainer(user)
    end

    it 'does not mutate LF line endings' do
      visit(project_edit_blob_path(project_with_lf, tree_join(project_with_lf.default_branch, 'lf_file.txt')))
      wait_for_requests

      find('.file-editor', match: :first)

      click_button('Commit changes')

      within_testid('commit-change-modal') do
        fill_in(:commit_message, with: 'New commit message', visible: true)
        choose(option: true)
        fill_in(:branch_name, with: 'new_branch_name', visible: true)
        click_button('Commit changes')
      end

      expect(page).to have_content('Changes 0')
    end

    it 'does not mutate CRLF line endings' do
      visit(project_edit_blob_path(project_with_crlf, tree_join(project_with_crlf.default_branch, 'crlf_file.txt')))
      wait_for_requests

      find('.file-editor', match: :first)

      click_button('Commit changes')

      within_testid('commit-change-modal') do
        fill_in(:commit_message, with: 'New commit message', visible: true)
        choose(option: true)
        fill_in(:branch_name, with: 'new_branch_name', visible: true)
        click_button('Commit changes')
      end

      expect(page).to have_content('Changes 0')
    end
  end
end
