require 'spec_helper'

describe 'Discussion Comments Merge Request', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_merge_request_path(project, merge_request)
  end

  it_behaves_like 'discussion comments', 'merge request'
end
