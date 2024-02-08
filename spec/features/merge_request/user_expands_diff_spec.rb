# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User expands diff', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:merge_request) { create(:merge_request, source_branch: 'expand-collapse-files', source_project: project, target_project: project) }

  before do
    allow(Gitlab::CurrentSettings).to receive(:diff_max_patch_bytes).and_return(100.bytes)

    visit(diffs_project_merge_request_path(project, merge_request))

    wait_for_requests
  end

  it 'allows user to expand diff' do
    page.within find("[id='4c76a1271e41072d7da9fe40bf0f79f7384d472a']") do
      find_by_testid('expand-button').click

      wait_for_requests

      expect(page).not_to have_content('Expand file')
      expect(page).to have_selector('.code')
    end
  end
end
