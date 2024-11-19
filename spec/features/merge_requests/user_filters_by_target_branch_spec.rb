# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > User filters by target branch', :js, feature_category: :code_review_workflow do
  include FilteredSearchHelpers

  let!(:project) { create(:project, :public, :repository) }
  let!(:user)    { project.creator }
  let!(:mr1) { create(:merge_request, source_project: project, target_project: project, source_branch: 'feature', target_branch: 'master') }
  let!(:mr2) { create(:merge_request, source_project: project, target_project: project, source_branch: 'feature', target_branch: 'merged-target') }

  before do
    sign_in(user)
    visit project_merge_requests_path(project)
  end

  context 'filtering by target-branch:master' do
    it 'applies the filter' do
      select_tokens 'Target Branch', 'master', search_token: true, submit: true

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content mr1.title
      expect(page).not_to have_content mr2.title
    end
  end

  context 'filtering by target-branch:merged-target' do
    it 'applies the filter' do
      select_tokens 'Target Branch', 'merged-target', search_token: true, submit: true

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).not_to have_content mr1.title
      expect(page).to have_content mr2.title
    end
  end
end
