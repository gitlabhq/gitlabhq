# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diffs', :js, feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:project) { create(:project, :public, :repository) }
  let(:view) { 'inline' }

  before do
    visit(diffs_project_merge_request_path(project, merge_request, view: view))

    wait_for_requests

    find('.js-toggle-tree-list').click
  end

  shared_examples 'unfold diffs' do
    it 'unfolds diffs upwards' do
      first('.js-unfold').click

      page.within('.file-holder[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd"]') do
        expect(find('.text-file')).to have_content('fileutils')
        expect(page).to have_selector('[data-interop-type="new"] [data-linenumber="1"]')
      end
    end

    it 'unfolds diffs in the middle' do
      page.within('.file-holder[id="2f6fcd96b88b36ce98c38da085c795a27d92a3dd"]') do
        first('.js-unfold-all').click

        expect(page).to have_selector('[data-interop-type="new"] [data-linenumber="24"]', count: 1)
        expect(page).not_to have_selector('[data-interop-type="new"] [data-linenumber="1"]')
      end
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
    expect(page).to have_selector('li', text: 'Side-by-side')
    expect(page).to have_selector('li', text: 'Inline')
  end

  it 'hides loading spinner after load' do
    expect(page).not_to have_selector('.mr-loading-status .loading', visible: true)
  end

  it 'expands all diffs', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/333628' do
    first('.diff-toggle-caret').click

    expect(page).to have_button('Expand all')

    click_button 'Expand all'
    wait_for_requests

    expect(page).not_to have_button('Expand all')
  end

  context 'when in the inline view' do
    include_examples 'unfold diffs'
  end

  context 'when in the side-by-side view' do
    let(:view) { 'parallel' }

    it 'shows diffs in parallel' do
      expect(page).to have_css('.parallel')
    end

    it 'toggles container class' do
      expect(page).not_to have_css('.content-wrapper > .project-highlight-puc.container-fluid.container-limited')

      click_link 'Commits'

      expect(page).to have_css('.content-wrapper > .project-highlight-puc.container-fluid.container-limited')
    end

    include_examples 'unfold diffs'
  end
end
