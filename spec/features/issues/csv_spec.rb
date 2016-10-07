require 'spec_helper'

describe 'Issues csv', feature: true do
  let(:user)    { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let(:milestone) { create(:milestone, title: 'v1.0', project: project) }
  let(:idea_label) { create(:label, project: project, title: 'Idea') }
  let(:feature_label) { create(:label, project: project, title: 'Feature') }
  let!(:issue)  { create(:issue, project: project, author: user) }

  before { login_as(user) }

  it "downloads from a project's issue index" do
    visit namespace_project_issues_path(project.namespace, project)
    click_on 'Download CSV'

    expect(page.response_headers['Content-Type']).to include('csv')
  end

  it 'ignores pagination' do
    create_list(:issue, 30, project: project, author: user)

    visit namespace_project_issues_path(project.namespace, project)
    click_on 'Download CSV'

    expect(csv.count).to eq 31
  end

  it 'uses filters from issue index' do
    visit namespace_project_issues_path(project.namespace, project, state: :closed)
    click_on 'Download CSV'

    expect(csv.count).to eq 0
  end

  def visit_project_csv
    visit namespace_project_issues_path(project.namespace, project, format: :csv)
  end

  it 'avoids excessive database calls' do
    control_count = ActiveRecord::QueryRecorder.new{ visit_project_csv }.count
    create_list(:labeled_issue,
                10,
                project: project,
                assignee: user,
                author: user,
                milestone: milestone,
                labels: [feature_label, idea_label])
    expect{ visit_project_csv }.not_to exceed_query_limit(control_count)
  end

  context 'includes' do
    before do
      issue.update!(milestone: milestone,
                    assignee: user,
                    description: 'Issue with details',
                    due_date: DateTime.new(2014, 3, 2),
                    created_at: DateTime.new(2015, 4, 3, 2, 1, 0),
                    updated_at: DateTime.new(2016, 5, 4, 3, 2, 1),
                    labels: [feature_label, idea_label])

      visit_project_csv
    end

    specify 'title' do
      expect(csv[0]['Title']).to eq issue.title
    end

    specify 'description' do
      expect(csv[0]['Description']).to eq issue.description
    end

    specify 'author name' do
      expect(csv[0]['Author']).to eq issue.author_name
    end

    specify 'assignee name' do
      expect(csv[0]['Assignee']).to eq issue.assignee_name
    end

    specify 'confidential' do
      expect(csv[0]['Confidential']).to eq 'false'
    end

    specify 'milestone' do
      expect(csv[0]['Milestone']).to eq issue.milestone.title
    end

    specify 'labels' do
      expect(csv[0]['Labels']).to eq 'Feature,Idea'
    end

    specify 'due_date' do
      expect(csv[0]['Due Date']).to eq '2014-03-02'
    end

    specify 'created_at' do
      expect(csv[0]['Created At (UTC)']).to eq '2015-04-03 02:01:00'
    end

    specify 'updated_at' do
      expect(csv[0]['Updated At (UTC)']).to eq '2016-05-04 03:02:01'
    end
  end

  context 'with minimal details' do
    it 'renders labels as nil' do
      visit_project_csv

      expect(csv[0]['Labels']).to eq nil
    end
  end
end
