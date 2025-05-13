# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diffs', :js, feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end

  let_it_be(:project) { create(:project, :public, :repository) }
  let(:view) { 'inline' }
  let(:last_commit_text) { 'Subproject commit 79bceae69cb5750d6567b223597999bfa91cb3b9' }

  before do
    stub_feature_flags(rapid_diffs: true)
    visit(diffs_project_merge_request_path(project, merge_request, view: view, rapid_diffs: true))

    wait_for_requests
  end

  it 'shows the last diff file' do
    expect(page).to have_selector('[data-testid="rd-diff-file"]', text: last_commit_text)
  end

  it 'has matching diff file order' do
    skip 'MR streaming has wrong order for the diffs, remove skip once the order is correct'
    browser_item_selector = '[data-testid="file-row-name-container"]:not(:has([data-testid="folder-open-icon"]))'
    browser_item_titles = page.find_all(browser_item_selector).map { |element| element.text.delete("\n").strip }
    # TODO: fix this selector, do not rely on classes
    diff_titles = page.find_all('.rd-diff-file-title strong:first-of-type').map do |element|
      element.text.delete("\n").strip
    end
    expect(browser_item_titles.each_with_index.all? do |browser_item_title, index|
      diff_titles[index].end_with?(browser_item_title)
    end).to be(true)
  end
end
