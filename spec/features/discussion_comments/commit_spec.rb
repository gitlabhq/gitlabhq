require 'spec_helper'

describe 'Discussion Comments Commit', :js do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_commit_path(project, sample_commit.id)
  end

  it_behaves_like 'discussion comments', 'commit'
end
