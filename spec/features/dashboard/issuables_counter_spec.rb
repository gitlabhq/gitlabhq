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

    expect_counters('issues', '1', n_("%d assigned issue", "%d assigned issues", 1) % 1)

    issue.update!(assignees: [])

    Users::AssignedIssuesCountService.new(current_user: user).delete_cache

    travel_to(3.minutes.from_now) do
      visit issues_path

      expect_counters('issues', '0', n_("%d assigned issue", "%d assigned issues", 0) % 0)
    end
  end

  it 'reflects dashboard merge requests count', :js do
    visit merge_requests_path

    expect_counters('merge_requests', '1', n_("%d merge request", "%d merge requests", 1) % 1)

    merge_request.update!(assignees: [])

    user.invalidate_cache_counts

    travel_to(3.minutes.from_now) do
      visit merge_requests_path

      expect_counters('merge_requests', '0', n_("%d merge request", "%d merge requests", 0) % 0)
    end
  end

  def issues_path
    issues_dashboard_path(assignee_username: user.username)
  end

  def merge_requests_path
    merge_requests_dashboard_path(assignee_username: user.username)
  end

  def expect_counters(issuable_type, count, badge_label)
    dashboard_count = find('.gl-tabs-nav li a.active')

    expect(dashboard_count).to have_content(count)
    expect(page).to have_css(".dashboard-shortcuts-#{issuable_type}", visible: :all, text: count)
    expect(page).to have_css("span[aria-label='#{badge_label}']", visible: :all, text: count)
  end
end
