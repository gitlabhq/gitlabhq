require 'spec_helper'

describe 'Discussion Comments Snippet', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:snippet) { create(:project_snippet, :private, project: project, author: user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit project_snippet_path(project, snippet)
  end

  it_behaves_like 'discussion comments', 'snippet'
end
