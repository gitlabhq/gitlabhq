# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Action focused merge request dashboard', :js, feature_category: :code_review_workflow do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:project) { create(:project) }
  let_it_be(:assigned_merge_request) do
    create(:merge_request,
      assignees: [current_user],
      source_project: project,
      author: current_user)
  end

  let_it_be(:review_requested_merge_request) do
    create(:merge_request,
      reviewers: [current_user],
      source_branch: 'review',
      source_project: project)
  end

  let_it_be(:returned_to_user) do
    create(:merge_request,
      assignee: [current_user],
      reviewers: create_list(:user, 1),
      source_branch: 'returned',
      source_project: project)
  end

  before_all do
    project.add_maintainer(current_user)

    returned_to_user.merge_request_reviewers.update_all(state: :requested_changes)
  end

  before do
    stub_feature_flags(merge_request_dashboard: true)

    sign_in(current_user)

    visit merge_requests_dashboard_path

    wait_for_requests
  end

  it 'passes axe automated accessibility testing' do
    expect(page).to have_selector('[data-testid="merge-request"]', count: 3)

    # TODO: Remove the skipping test when we change the search tab to be part of the Vue app
    expect(page).to be_axe_clean.within('#content-body').skipping :'aria-required-children'
  end
end
