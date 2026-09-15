# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diffs', :js, feature_category: :code_review_workflow do
  include RapidDiffsHelpers

  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let(:project) { create(:project, :public, :repository) }
  let(:view) { 'inline' }

  before do
    visit(diffs_project_merge_request_path(project, merge_request, view: view))

    wait_for_requests

    find_by_testid('file-tree-button').click
  end

  shared_examples 'unfold diffs' do
    it 'unfolds diffs upwards' do
      within_diff_file('files/ruby/popen.rb') do
        find('button[data-expand-direction="up"]', match: :first).click

        expect(page).to have_content('fileutils')
        expect(page).to have_selector('[data-position="new"] [data-line-number="1"]')
      end
    end

    it 'unfolds diffs in the middle' do
      within_diff_file('files/ruby/popen.rb') do
        find('button[data-expand-direction="both"]', match: :first).click

        expect(page).to have_selector('[data-position="new"] [data-line-number="24"]', count: 1)
        expect(page).not_to have_selector('[data-position="new"] [data-line-number="1"]')
      end
    end

    it 'unfolds diffs downwards' do
      within_diff_file('files/ruby/popen.rb') do
        find('button[data-expand-direction="down"]', match: :first).click

        expect(page).to have_content('.popen3')
      end
    end

    it 'unfolds diffs to the end' do
      within_diff_file('files/ruby/regex.rb') do
        expect(page).to have_content('end')
      end
    end
  end

  it 'shows diffs' do
    open_diff_view_preferences

    expect(page).to have_css('[role="option"]', text: 'Side-by-side')
    expect(page).to have_css('[role="option"]', text: 'Inline')
  end

  it 'hides loading spinner after load' do
    expect(page).not_to have_selector('.mr-loading-status .loading', visible: :visible)
  end

  it 'expands all diffs' do
    find('button[aria-label="Collapse all files"]').click
    expect(page).to have_no_css('diff-file details[open]', visible: :all)

    find('button[aria-label="Expand all files"]').click
    expect(page).to have_css('diff-file details[open]', visible: :all)
  end

  context 'when in the inline view' do
    include_examples 'unfold diffs'
  end

  context 'when in the side-by-side view' do
    let(:view) { 'parallel' }

    it 'shows diffs in parallel' do
      expect(page).to have_css('[data-testid="hunk-lines-parallel"]')
    end

    it 'toggles container class' do
      expect(page).not_to have_css('.project-highlight-puc.container-fluid.container-limited')

      click_link 'Commits'

      expect(page).to have_css('.project-highlight-puc.container-fluid.container-limited')
    end

    include_examples 'unfold diffs'
  end
end
