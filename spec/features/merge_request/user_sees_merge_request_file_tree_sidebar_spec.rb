# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees merge request file tree sidebar', :js, feature_category: :code_review_workflow do
  include MergeRequestDiffHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let(:user) { project.creator }
  let(:sidebar) { find('.diff-tree-list') }
  let(:sidebar_scroller) { sidebar.find('.vue-recycle-scroller') }

  before do
    sign_in(user)
    visit diffs_project_merge_request_path(project, merge_request)
    wait_for_requests
  end

  it 'sees file tree sidebar' do
    expect(page).to have_selector('[data-testid="file-tree-container"]')
  end

  shared_examples 'last entry clickable' do
    specify do
      # The file browser height is recalculated asynchronously (and debounced
      # twice) as the tree scrolls, so the last row can briefly sit below the
      # fold. Keep scrolling to the bottom until the layout settles and the last
      # entry is actually clickable, rather than sampling `obscured?` once.
      button = nil
      wait_for('last file tree entry to be clickable') do
        sidebar_scroller.execute_script('this.scrollBy(0,99999)')
        button = find_all('[data-testid="file-tree-container"] nav button').last
        button && !button.obscured?
      end

      title = button.find('[data-testid=file-row-name-container]')[:title]
      button.click

      expect(page).to have_selector(".file-title-name[title*=\"#{title}\"]")
    end
  end

  context 'with quarantine', quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/9506' do
    it_behaves_like 'last entry clickable'
  end

  context 'when viewing using file-by-file mode' do
    let(:user) { create(:user, view_diffs_file_by_file: true) }

    context 'with quarantine', quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/9452' do
      it_behaves_like 'last entry clickable'
    end

    context 'when navigating to the next file' do
      before do
        find_by_testid('nextButton').click
        wait_for_requests
      end

      it_behaves_like 'last entry clickable'
    end
  end
end
