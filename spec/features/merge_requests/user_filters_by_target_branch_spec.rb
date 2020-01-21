# frozen_string_literal: true

require 'spec_helper'

describe 'Merge Requests > User filters by target branch', :js do
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
      input_filtered_search('target-branch=master')

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).to have_content mr1.title
      expect(page).not_to have_content mr2.title
    end
  end

  context 'filtering by target-branch:merged-target' do
    it 'applies the filter' do
      input_filtered_search('target-branch=merged-target')

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)
      expect(page).not_to have_content mr1.title
      expect(page).to have_content mr2.title
    end
  end

  context 'filtering by target-branch:feature' do
    it 'applies the filter' do
      input_filtered_search('target-branch=feature')

      expect(page).to have_issuable_counts(open: 0, closed: 0, all: 0)
      expect(page).not_to have_content mr1.title
      expect(page).not_to have_content mr2.title
    end
  end
end
