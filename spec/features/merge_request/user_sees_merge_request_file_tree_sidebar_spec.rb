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
      sidebar_scroller.execute_script('this.scrollBy(0,99999)')
      button = find_all('[data-testid="file-tree-container"] nav button').last
      title = button.find('[data-testid=file-row-name-container]')[:title]
      expect(button.obscured?).to be_falsy
      button.click
      expect(page).to have_selector(".file-title-name[title*=\"#{title}\"]")
    end
  end

  context 'with quarantine', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/512092' do
    it_behaves_like 'last entry clickable'
  end

  context 'when viewing using file-by-file mode' do
    let(:user) { create(:user, view_diffs_file_by_file: true) }

    context 'with quarantine', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/517688' do
      it_behaves_like 'last entry clickable'
    end

    context 'when navigating to the next file' do
      before do
        click_link 'Next'
        wait_for_requests
        # when we click the Next button the viewport will be scrolled a bit into the diffs view
        # this will cause for the file tree sidebar height to be recalculated
        # because this logic is async and debounced twice we have to wait for the layout to stabilize
        sleep(1)
      end

      it_behaves_like 'last entry clickable'
    end
  end
end
