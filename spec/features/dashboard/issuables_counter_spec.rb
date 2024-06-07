# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Navigation bar counter', :use_clean_rails_memory_store_caching, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    issue.assignees = [user]
    merge_request.update!(assignees: [user])
    sign_in(user)
  end

  it 'reflects dashboard issues count', :js do
    visit issues_path

    expect_issue_count(1)

    issue.update!(assignees: [])

    user.invalidate_cache_counts

    visit issues_path

    expect_issue_count(0)
  end

  it 'reflects dashboard merge requests count', :js do
    visit merge_requests_path

    expect_merge_request_count(1)

    merge_request.update!(assignees: [])

    user.invalidate_cache_counts

    visit merge_requests_path

    expect_merge_request_count(0)
  end

  def issues_path
    issues_dashboard_path(assignee_username: user.username)
  end

  def merge_requests_path
    merge_requests_dashboard_path(assignee_username: user.username)
  end

  def expect_issue_count(count)
    dashboard_count = find('.gl-tabs-nav li a.active')
    expect(dashboard_count).to have_content(count)

    within_testid('super-sidebar') do
      expect(page).to have_link("Assigned issues #{count}")
    end
  end

  def expect_merge_request_count(count)
    dashboard_count = find('.gl-tabs-nav li a.active')
    expect(dashboard_count).to have_content(count)

    within_testid('super-sidebar') do
      expect(page).to have_button("Merge requests #{count}")
    end
  end
end
