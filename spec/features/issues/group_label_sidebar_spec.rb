require 'rails_helper'

describe 'Group label on issue' do
  it 'renders link to the project issues page' do
    group = create(:group)
    project = create(:project, :public, namespace: group)
    feature = create(:group_label, group: group, title: 'feature')
    issue = create(:labeled_issue, project: project, labels: [feature])
    label_link = project_issues_path(project, label_name: [feature.name])

    visit project_issue_path(project, issue)

    link = find('.issuable-show-labels a')

    expect(link[:href]).to eq(label_link)
  end
end
