# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group label on issue', :with_license, feature_category: :team_planning do
  it 'renders link to the project issues page', :js do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
    stub_feature_flags(work_item_view_for_issues: true)

    group = create(:group)
    project = create(:project, :public, namespace: group)
    feature = create(:group_label, group: group, title: 'feature')
    issue = create(:labeled_issue, project: project, labels: [feature])

    visit project_issue_path(project, issue)

    expect(page).to have_link(feature.title,
      href: CGI.unescape(project_issues_path(project, label_name: [feature.name])))
  end
end
