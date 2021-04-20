# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Navigation bar counter', :use_clean_rails_memory_store_caching do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    issue.assignees = [user]
    merge_request.update!(assignees: [user])
    sign_in(user)
  end

  it 'reflects dashboard issues count' do
    visit issues_path

    expect_counters('issues', '1')

    issue.assignees = []

    user.invalidate_cache_counts

    travel_to(3.minutes.from_now) do
      visit issues_path

      expect_counters('issues', '0')
    end
  end

  it 'reflects dashboard merge requests count' do
    visit merge_requests_path

    expect_counters('merge_requests', '1')

    merge_request.update!(assignees: [])

    user.invalidate_cache_counts

    travel_to(3.minutes.from_now) do
      visit merge_requests_path

      expect_counters('merge_requests', '0')
    end
  end

  def issues_path
    issues_dashboard_path(assignee_username: user.username)
  end

  def merge_requests_path
    merge_requests_dashboard_path(assignee_username: user.username)
  end

  def expect_counters(issuable_type, count)
    dashboard_count = find('.nav-links li.active')
    nav_count = find(".dashboard-shortcuts-#{issuable_type}")
    header_count = find(".header-content .#{issuable_type.tr('_', '-')}-count")

    expect(dashboard_count).to have_content(count)
    expect(nav_count).to have_content(count)
    expect(header_count).to have_content(count)
  end
end
