require 'rails_helper'

describe 'Group label on issue', :feature do
  it 'renders link to the project issues page' do
    group = create(:group)
    project = create(:empty_project, :public, namespace: group)
    feature = create(:group_label, group: group, title: 'feature')
    issue = create(:labeled_issue, project: project, labels: [feature])
    label_link = namespace_project_issues_path(
      project.namespace,
      project,
      label_name: [feature.name]
    )

    visit namespace_project_issue_path(project.namespace, project, issue)

    link = find('.issuable-show-labels a')

    expect(link[:href]).to eq(label_link)
  end
end
