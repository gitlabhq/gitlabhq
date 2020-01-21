# frozen_string_literal: true

require 'spec_helper'

describe 'User views diffs', :js do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end
  let(:project) { create(:project, :public, :repository) }

  before do
    stub_feature_flags(diffs_batch_load: false)
    visit(diffs_project_merge_request_path(project, merge_request))

    wait_for_requests

    find('.js-toggle-tree-list').click
  end

  shared_examples 'unfold diffs' do
    it 'unfolds diffs upwards' do
      first('.js-unfold').click
      expect(find('.file-holder[id="a5cc2925ca8258af241be7e5b0381edf30266302"] .text-file')).to have_content('.bundle')
    end

    it 'unfolds diffs to the start' do
      first('.js-unfold-all').click
      expect(find('.file-holder[id="a5cc2925ca8258af241be7e5b0381edf30266302"] .text-file')).to have_content('.rbc')
    end

    it 'unfolds diffs downwards' do
      first('.js-unfold-down').click
      expect(find('.file-holder[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd"] .text-file')).to have_content('.popen3')
    end

    it 'unfolds diffs to the end' do
      page.all('.js-unfold-down').last
      expect(find('.file-holder[id="6eb14e00385d2fb284765eb1cd8d420d33d63fc9"] .text-file')).to have_content('end')
    end
  end

  it 'shows diffs' do
    find('.js-show-diff-settings').click

    expect(page).to have_css('.tab-content #diffs.active')
    expect(page).to have_css('#parallel-diff-btn', count: 1)
    expect(page).to have_css('#inline-diff-btn', count: 1)
  end

  it 'hides loading spinner after load' do
    expect(page).not_to have_selector('.mr-loading-status .loading', visible: true)
  end

  it 'expands all diffs' do
    first('#a5cc2925ca8258af241be7e5b0381edf30266302 .js-file-title').click

    expect(page).to have_button('Expand all')

    click_button 'Expand all'

    expect(page).not_to have_button('Expand all')
  end

  context 'when in the inline view' do
    include_examples 'unfold diffs'
  end

  context 'when in the side-by-side view' do
    before do
      find('.js-show-diff-settings').click

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
