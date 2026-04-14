# frozen_string_literal: true

require 'spec_helper'

# Accessibility Test for Golden User Journey: Writing Code
#
# Golden user journey for writing and editing code in GitLab
#
# E2E Test References:
#
# Single-file editor:
#   - qa/qa/specs/features/browser_ui/3_create/source_editor/source_editor_toolbar_spec.rb
#     Context: Create
#     - can preview markdown side-by-side while editing
#     Page interactions:
#       - visits project page
#       - interacts with project show
#       - interacts with file show
#       - interacts with file edit
#       - visit
#       - click file
#       - remove content
#       - add content
#       - preview
#       - click commit changes in header
#       - commit changes through modal
#       - sign in (login)
#
# Git interactions:
#   - qa/qa/specs/features/browser_ui/3_create/repository/user_views_commit_diff_patch_spec.rb
#     Context: Create
#     - user views raw email patch
#     - user views raw commit diff
#     Page interactions:
#       - visits project page
#       - interacts with project show
#       - interacts with project commit show
#       - visit
#       - click commit
#       - sign in (login)

RSpec.describe 'Accessibility: Writing Code', :js, feature_category: :source_code_management do
  include Features::SourceEditorSpecHelpers
  include Features::BlobSpecHelpers

  let_it_be(:project_maintainer) { create(:user, :with_namespace) }
  let_it_be(:project) { create(:project, :repository) }

  before_all do
    project.add_maintainer(project_maintainer)
  end

  before do
    stub_feature_flags(inline_blame: true)
    sign_in(project_maintainer)
  end

  def navigate_from_tree_to_blob_viewer
    within_testid('file-tree-table') do
      click_link('README.md')
    end
    wait_for_requests
  end

  # ========================================================================
  # FOCUS AREA: Single-file editor
  # ========================================================================

  context 'when single-file editor' do
    it 'passes axe when visiting project page' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body')
    end

    it 'passes axe when clicking on a file' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      expect(page).to be_axe_clean.within('#content-body')
    end

    it 'passes axe when viewing file in code viewer' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      find_by_testid('simple-blob-viewer-button').click
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'valid-lang'
    end

    it 'passes axe when viewing file blame' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      find_by_testid('blame-button').click
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'valid-lang'
    end

    it 'passes axe when navigating back to file via breadcrumb' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      find_by_testid('blame-button').click
      wait_for_requests

      within('#content-body .breadcrumb') do
        click_link('README.md')
      end
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'valid-lang'
    end

    it 'passes axe when editing file in single-file editor' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      edit_in_single_file_editor
      find('.file-editor', match: :first)
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body')
    end

    it 'passes axe when previewing markdown content' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      edit_in_single_file_editor
      find('.file-editor', match: :first)
      wait_for_requests

      editor_set_value('# Updated README content')

      click_link('Preview')
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body')
    end

    it 'passes axe when returning to write mode from preview' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      edit_in_single_file_editor
      find('.file-editor', match: :first)
      wait_for_requests

      editor_set_value('# Updated README content')

      click_link('Preview')
      wait_for_requests

      click_link('Write')
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body')
    end

    it 'passes axe when previewing changes before committing' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      edit_in_single_file_editor
      find('.file-editor', match: :first)
      wait_for_requests

      editor_set_value('# Updated README content')

      click_link('Write')
      wait_for_requests

      click_link('Preview')
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'scrollable-region-focusable'
    end

    it 'passes axe when committing changes via modal' do
      visit project_tree_path(project, project.repository.root_ref)
      wait_for_requests

      navigate_from_tree_to_blob_viewer

      edit_in_single_file_editor
      find('.file-editor', match: :first)
      wait_for_requests

      editor_set_value('# Updated README content')

      click_button('Commit changes')

      within_testid('commit-change-modal') do
        expect(page).to be_axe_clean.skipping :'landmark-unique'
      end

      within_testid('commit-change-modal') do
        click_button 'Commit changes'
      end
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'link-in-text-block'
    end
  end

  # ========================================================================
  # FOCUS AREA: Git interactions
  # ========================================================================

  context 'when git interactions' do
    # Note: The E2E test reference (user_views_commit_diff_patch_spec.rb) tests
    # downloading raw formats (.patch and .diff files), which are file downloads
    # without UI rendering and therefore not suitable for accessibility testing.
    # This context tests the commit viewing UI instead.

    let_it_be(:commit) { project.repository.commit }

    before_all do
      stub_feature_flags(rapid_diffs_on_commit_show: true)
      create(:ci_pipeline, project: project, sha: commit.sha, ref: 'master')
    end

    it 'passes axe when viewing commit details' do
      visit project_commit_path(project, commit.id)
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'link-in-text-block'
    end

    it 'passes axe when opening commit options dropdown' do
      visit project_commit_path(project, commit.id)
      wait_for_requests

      find_by_testid('commit-options-dropdown').click
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'link-in-text-block'
    end

    it 'passes axe when closing commit options dropdown' do
      visit project_commit_path(project, commit.id)
      wait_for_requests

      find_by_testid('commit-options-dropdown').click
      wait_for_requests

      find_by_testid('commit-options-dropdown').click
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'link-in-text-block'
    end

    it 'passes axe when viewing commit pipelines' do
      visit project_commit_path(project, commit.id)
      wait_for_requests

      click_link('Pipelines')
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'link-in-text-block', :'link-name'
    end

    it 'passes axe when switching back to commit changes' do
      visit project_commit_path(project, commit.id)
      wait_for_requests

      click_link('Pipelines')
      wait_for_requests

      click_link('Changes')
      wait_for_requests

      expect(page).to be_axe_clean.within('#content-body').skipping :'link-in-text-block'
    end
  end
end
