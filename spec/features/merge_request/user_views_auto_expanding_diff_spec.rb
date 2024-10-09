# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views diffs file-by-file', :js, feature_category: :code_review_workflow do
  let(:merge_request) do
    create(:merge_request, source_branch: 'squash-large-files', source_project: project, target_project: project)
  end

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user, view_diffs_file_by_file: true) }

  before do
    project.add_developer(user)

    sign_in(user)

    visit(diffs_project_merge_request_path(project, merge_request, anchor: '5091f7b9dd6202e37eaedd73d7b75d82f25fdb61'))

    wait_for_requests
  end

  it 'shows diffs file-by-file' do
    page.within('#diffs') do
      expect(page).not_to have_content('This diff is collapsed')

      find_by_testid('gl-pagination-next').click

      expect(page).not_to have_content('This diff is collapsed')
      expect(page).to have_selector('.diff-file .file-title', text: 'large_diff_renamed.md')
    end
  end
end
