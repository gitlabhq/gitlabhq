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
    scroll_into_view
  end

  it 'sees file tree sidebar' do
    expect(page).to have_selector('.file-row[role=button]')
  end

  # TODO: fix this test
  # For some reason the browser in CI doesn't update the file tree sidebar when review bar is shown
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118378#note_1403906356
  #
  # it 'has last entry visible with discussions enabled' do
  #   add_diff_line_draft_comment('foo', find('.line_holder', match: :first))
  #   scroll_into_view
  #   scroll_to_end
  #   button = find_all('.file-row[role=button]').last
  #   expect(button.obscured?).to be_falsy
  # end

  shared_examples 'shows last visible file in sidebar' do
    it 'shows last file' do
      scroll_to_end
      button = find_all('.file-row[role=button]').last
      title = button.find('[data-testid=file-row-name-container]')[:title]
      button.click
      expect(page).to have_selector(".file-title-name[title*=\"#{title}\"]")
    end
  end

  it_behaves_like 'shows last visible file in sidebar'

  context 'when viewing using file-by-file mode' do
    let(:user) { create(:user, view_diffs_file_by_file: true) }

    it_behaves_like 'shows last visible file in sidebar'
  end

  def scroll_into_view
    sidebar.execute_script("this.scrollIntoView({ block: 'end' })")
  end

  def scroll_to_end
    sidebar_scroller.execute_script('this.scrollBy(0,99999)')
  end
end
