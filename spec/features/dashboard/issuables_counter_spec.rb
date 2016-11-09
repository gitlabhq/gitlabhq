require 'spec_helper'

describe 'Navigation bar counter', feature: true, js: true, caching: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    login_as(user)
    visit issues_dashboard_path
  end

  it 'reflects dashboard issues count' do
    create(:issue, project: project, assignee: user)
    visit issues_dashboard_path

    dashboard_count = find('li.active span.badge')
    nav_count = find('.dashboard-shortcuts-issues span.count')

    expect(dashboard_count).to have_content('0')
    expect(nav_count).to have_content('0')
  end

  it 'reflects dashboard merge requests count' do
    create(:merge_request, assignee: user)
    visit merge_requests_dashboard_path

    dashboard_count = find('li.active span.badge')
    nav_count = find('.dashboard-shortcuts-merge_requests span.count')

    expect(dashboard_count).to have_content('0')
    expect(nav_count).to have_content('0')
  end
end
