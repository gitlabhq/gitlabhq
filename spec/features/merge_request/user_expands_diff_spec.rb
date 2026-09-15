# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User expands diff', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_branch: 'expand-collapse-files', source_project: project, target_project: project) }

  before do
    allow(Gitlab::Git::Diff).to receive(:patch_safe_limit_bytes).and_return(100.bytes)

    visit(diffs_project_merge_request_path(project, merge_request))

    wait_for_requests
  end

  it 'allows user to expand diff' do
    file = find('diff-file button', text: 'Show changes', match: :first).ancestor('diff-file')
    file_name = file.find('header h2').text

    within(file) do
      click_button 'Show changes'
    end

    wait_for_requests

    expanded = find('diff-file header', text: file_name, match: :first).ancestor('diff-file')

    expect(expanded).to have_no_button('Show changes')
    expect(expanded).to have_selector('[data-hunk-lines]')
  end
end
