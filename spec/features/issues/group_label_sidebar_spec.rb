# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group label on issue', :with_license, feature_category: :team_planning do
  it 'renders link to the project issues page', :js do
    group = create(:group)
    project = create(:project, :public, namespace: group)
    feature = create(:group_label, group: group, title: 'feature')
    issue = create(:labeled_issue, project: project, labels: [feature])
    label_link = project_issues_path(project, label_name: [feature.name])

    visit project_issue_path(project, issue)

    link = find('.issuable-show-labels a')

    expect(CGI.unescape(link[:href])).to include(CGI.unescape(label_link))
  end
end
