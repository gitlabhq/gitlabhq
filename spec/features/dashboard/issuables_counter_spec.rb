require 'spec_helper'

describe 'Navigation bar counter', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project, namespace: user.namespace) }

  before do
    login_as(user)
  end

  it 'reflects dashboard issues count' do
    issue = create(:issue, project: project, assignee: user)
    visit issues_dashboard_path

    dashboard_count = find('li.active span.badge')
    nav_count = find('.dashboard-shortcuts-issues span.count')

    expect(nav_count).to have_content('1')
    expect(dashboard_count).to have_content('1')

    issue.assignee = nil
    visit issues_dashboard_path

    dashboard_count = find('li.active span.badge')
    nav_count = find('.dashboard-shortcuts-issues span.count')

    expect(nav_count).to have_content('1')
    expect(dashboard_count).to have_content('1')
  end

  it 'reflects dashboard merge requests count' do
    merge_request = create(:merge_request, source_project: project, assignee: user)
    visit merge_requests_dashboard_path

    dashboard_count = find('li.active span.badge')
    nav_count = find('.dashboard-shortcuts-merge_requests span.count')

    expect(nav_count).to have_content('1')
    expect(dashboard_count).to have_content('1')

    merge_request.assignee = nil
    visit merge_requests_dashboard_path

    dashboard_count = find('li.active span.badge')
    nav_count = find('.dashboard-shortcuts-merge_requests span.count')

    expect(nav_count).to have_content('1')
    expect(dashboard_count).to have_content('1')
  end
end
