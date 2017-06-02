require 'spec_helper'

describe 'Project snippets', feature: true do
  context 'when the project has snippets' do
    let(:project) { create(:empty_project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.owner, project: project) }
    let!(:other_snippet) { create(:project_snippet) }

    context 'pagination' do
      before do
        allow(Snippet).to receive(:default_per_page).and_return(1)

        visit namespace_project_snippets_path(project.namespace, project)
      end

      it_behaves_like 'paginated snippets'
    end

    context 'list content' do
      it 'contains all project snippets' do
        visit namespace_project_snippets_path(project.namespace, project)

        expect(page).to have_selector('.snippet-row', count: 2)

        expect(page).to have_content(snippets[0].title)
        expect(page).to have_content(snippets[1].title)
      end
    end
  end
end
