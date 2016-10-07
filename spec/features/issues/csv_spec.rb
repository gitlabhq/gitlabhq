require 'spec_helper'

describe 'Issues csv', feature: true do
  let(:user)    { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let!(:issue)  { create(:issue, project: project) }

  before { login_as(user) }

  it "downloads from a project's issue index" do
    visit namespace_project_issues_path(project.namespace, project)
    click_on 'Download CSV'

    expect(page.response_headers['Content-Type']).to include('csv')
  end

  it 'ignores pagination' do
    create_list(:issue, 30, project: project)

    visit namespace_project_issues_path(project.namespace, project)
    click_on 'Download CSV'

    expect(csv.count).to eq 31
  end

  context 'includes' do
    let(:label1)    { create(:label, project: project, title: 'Feature') }
    let(:label2)    { create(:label, project: project, title: 'labels') }
    let(:milestone) { create(:milestone, title: "v1.0", project: project) }

    before do
      issue.update!(milestone: milestone, assignee: user, description: 'Issue with details', labels: [label1, label2])
      visit namespace_project_issues_path(project.namespace, project, format: :csv)
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
      expect(csv[0]['Labels']).to eq 'Feature,labels'
    end
  end

  context 'with minimal details' do
    it 'renders labels as nil' do
      visit namespace_project_issues_path(project.namespace, project, format: :csv)

      expect(csv[0]['Labels']).to eq nil
    end
  end
end
