# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests > User filters by source branch', :js, feature_category: :code_review_workflow do
  include FilteredSearchHelpers

  def create_mr(source_branch, target_branch, status)
    project.repository.create_branch(source_branch)

    create(:merge_request, status, source_project: project,
      target_branch: target_branch, source_branch: source_branch)
  end

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user)    { project.creator }

  let_it_be(:mr1) { create_mr('source1', 'target1', :opened) }
  let_it_be(:mr2) { create_mr('source2', 'target1', :opened) }
  let_it_be(:mr3) { create_mr('source1', 'target2', :merged) }
  let_it_be(:mr4) { create_mr('source1', 'target2', :closed) }

  before do
    sign_in(user)
    visit project_merge_requests_path(project)
  end

  context 'when filtering by source-branch:source1' do
    it 'applies the filter' do
      select_tokens 'Source Branch', 'source1', search_token: true, submit: true

      expect(page).to have_issuable_counts(open: 1, merged: 1, closed: 1, all: 3)
      expect(page).to have_content mr1.title
      expect(page).not_to have_content mr2.title
    end
  end

  context 'when filtering by source-branch:source2' do
    it 'applies the filter' do
      select_tokens 'Source Branch', 'source2', search_token: true, submit: true

      expect(page).to have_issuable_counts(open: 1, merged: 0, closed: 0, all: 1)
      expect(page).not_to have_content mr1.title
      expect(page).to have_content mr2.title
    end
  end
end
