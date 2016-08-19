require 'spec_helper'

describe "Dashboard > User sorts todos", feature: true do
  let(:user)    { create(:user) }
  let(:project) { create(:empty_project) }

  let(:label_1) { create(:label, title: 'label_1', project: project, priority: 1) }
  let(:label_2) { create(:label, title: 'label_2', project: project, priority: 2) }
  let(:label_3) { create(:label, title: 'label_3', project: project, priority: 3) }

  let(:issue_1) { create(:issue, title: 'issue_1', project: project) }
  let(:issue_2) { create(:issue, title: 'issue_2', project: project) }
  let(:issue_3) { create(:issue, title: 'issue_3', project: project) }
  let(:issue_4) { create(:issue, title: 'issue_4', project: project) }

  let!(:merge_request_1) { create(:merge_request, source_project: project, title: "merge_request_1") }

  before do
    create(:todo, user: user, project: project, target: issue_4, created_at: 5.hours.ago)
    create(:todo, user: user, project: project, target: issue_2, created_at: 4.hours.ago)
    create(:todo, user: user, project: project, target: issue_3, created_at: 3.hours.ago)
    create(:todo, user: user, project: project, target: issue_1, created_at: 2.hours.ago)
    create(:todo, user: user, project: project, target: merge_request_1, created_at: 1.hour.ago)

    merge_request_1.labels << label_1
    issue_3.labels         << label_1
    issue_2.labels         << label_3
    issue_1.labels         << label_2

    project.team << [user, :developer]
    login_as(user)
    visit dashboard_todos_path
  end

  it "sorts with oldest created todos first" do
    click_link "Last created"

    results_list = page.find('.todos-list')
    expect(results_list.all('p')[0]).to have_content("merge_request_1")
    expect(results_list.all('p')[1]).to have_content("issue_1")
    expect(results_list.all('p')[2]).to have_content("issue_3")
    expect(results_list.all('p')[3]).to have_content("issue_2")
    expect(results_list.all('p')[4]).to have_content("issue_4")
  end

  it "sorts with newest created todos first" do
    click_link "Oldest created"

    results_list = page.find('.todos-list')
    expect(results_list.all('p')[0]).to have_content("issue_4")
    expect(results_list.all('p')[1]).to have_content("issue_2")
    expect(results_list.all('p')[2]).to have_content("issue_3")
    expect(results_list.all('p')[3]).to have_content("issue_1")
    expect(results_list.all('p')[4]).to have_content("merge_request_1")
  end

  it "sorts by priority" do
    click_link "Priority"

    results_list = page.find('.todos-list')
    expect(results_list.all('p')[0]).to have_content("issue_3")
    expect(results_list.all('p')[1]).to have_content("merge_request_1")
    expect(results_list.all('p')[2]).to have_content("issue_1")
    expect(results_list.all('p')[3]).to have_content("issue_2")
    expect(results_list.all('p')[4]).to have_content("issue_4")
  end
end
