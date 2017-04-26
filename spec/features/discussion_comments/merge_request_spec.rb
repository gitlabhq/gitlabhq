require 'spec_helper'

describe 'Discussion Comments Merge Request', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_master(user)
    login_as(user)

    visit namespace_project_merge_request_path(project.namespace, project, merge_request)
  end

  it_behaves_like 'discussion comments', 'merge request'
end
