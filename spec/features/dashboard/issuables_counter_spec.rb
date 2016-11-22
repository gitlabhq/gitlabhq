require 'spec_helper'

describe 'Navigation bar counter', feature: true, js: true, caching: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, namespace: user.namespace) }
  let(:issue) { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    issue.update(assignee: user)
    merge_request.update(assignee: user)
    login_as(user)
  end

  it 'reflects dashboard issues count' do
    visit issues_dashboard_path

    expect_counters('issues', '1')

    issue.update(assignee: nil)
    visit issues_dashboard_path

    expect_counters('issues', '1')
  end

  it 'reflects dashboard merge requests count' do
    visit merge_requests_dashboard_path

    expect_counters('merge_requests', '1')

    merge_request.update(assignee: nil)
    visit merge_requests_dashboard_path

    expect_counters('merge_requests', '1')
  end

  def expect_counters(issuable_type, count)
    dashboard_count = find('li.active span.badge')
    nav_count = find(".dashboard-shortcuts-#{issuable_type} span.count")

    expect(nav_count).to have_content(count)
    expect(dashboard_count).to have_content(count)
  end
end
