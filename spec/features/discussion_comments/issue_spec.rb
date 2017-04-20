require 'spec_helper'

describe 'Discussion Comments Issue', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:issue) { create(:issue, project: project) }

  before do
    project.add_master(user)
    login_as(user)

    visit namespace_project_issue_path(project.namespace, project, issue)
  end

  it_behaves_like 'discussion comments', 'issue'
end
