require 'spec_helper'

describe 'Issues csv', feature: true do
  let(:user)    { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:issue)  { create(:issue, project: project) }

  before do
    login_as(user)
    visit namespace_project_issues_path(project.namespace, project, format: :csv)
  end

  it 'downloads as a file' do
    expect(page.response_headers['Content-Type']).to include('csv')
  end

  it 'includes title' do
    expect(csv[0]['Title']).to eq issue.title
  end

  it 'includes description' do
    expect(csv[0]['Description']).to eq issue.description
  end
end
