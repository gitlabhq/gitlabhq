require 'spec_helper'

describe 'Project snippets', feature: true do
  context 'when the project has snippets' do
    let(:project) { create(:empty_project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.owner, project: project) }
    before do
      allow(Snippet).to receive(:default_per_page).and_return(1)
      visit namespace_project_snippets_path(project.namespace, project)
    end

    it_behaves_like 'paginated snippets'
  end
end
