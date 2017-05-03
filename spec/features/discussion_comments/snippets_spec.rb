require 'spec_helper'

describe 'Discussion Comments Issue', :feature, :js do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:snippet) { create(:project_snippet, :private, project: project, author: user) }

  before do
    project.add_master(user)
    login_as(user)

    visit namespace_project_snippet_path(project.namespace, project, snippet)
  end

  it_behaves_like 'discussion comments', 'snippet'
end
