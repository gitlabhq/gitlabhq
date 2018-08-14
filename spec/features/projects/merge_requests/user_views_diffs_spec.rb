require 'spec_helper'

describe 'User views diffs', :js do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end
  let(:project) { create(:project, :public, :repository) }

  before do
    visit(diffs_project_merge_request_path(project, merge_request))

    wait_for_requests
  end

  shared_examples 'unfold diffs' do
    it 'unfolds diffs' do
      first('.js-unfold').click

      expect(find('.file-holder[id="a5cc2925ca8258af241be7e5b0381edf30266302"] .text-file')).to have_content('.bundle')
    end
  end

  it 'shows diffs' do
    expect(page).to have_css('.tab-content #diffs.active')
    expect(page).to have_css('#parallel-diff-btn', count: 1)
    expect(page).to have_css('#inline-diff-btn', count: 1)
  end

  it 'hides loading spinner after load' do
    expect(page).not_to have_selector('.mr-loading-status .loading', visible: true)
  end

  context 'when in the inline view' do
    include_examples 'unfold diffs'
  end

  context 'when in the side-by-side view' do
    before do
      click_button 'Side-by-side'

      wait_for_requests
    end

    it 'shows diffs in parallel' do
      expect(page).to have_css('.parallel')
    end

    it 'toggles container class' do
      expect(page).not_to have_css('.content-wrapper > .container-fluid.container-limited')

      click_link 'Commits'

      expect(page).to have_css('.content-wrapper > .container-fluid.container-limited')
    end

    include_examples 'unfold diffs'
  end
end
