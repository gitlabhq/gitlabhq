# frozen_string_literal: true

require 'spec_helper'

describe 'User expands diff', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_branch: 'expand-collapse-files', source_project: project, target_project: project) }

  before do
    stub_feature_flags(diffs_batch_load: false)

    allow(Gitlab::Git::Diff).to receive(:size_limit).and_return(100.kilobytes)
    allow(Gitlab::Git::Diff).to receive(:collapse_limit).and_return(10.kilobytes)

    visit(diffs_project_merge_request_path(project, merge_request))

    wait_for_requests
  end

  it 'allows user to expand diff' do
    page.within find('[id="6eb14e00385d2fb284765eb1cd8d420d33d63fc9"]') do
      click_link 'Click to expand it.'

      wait_for_requests

      expect(page).not_to have_content('Click to expand it.')
      expect(page).to have_selector('.code')
    end
  end
end
