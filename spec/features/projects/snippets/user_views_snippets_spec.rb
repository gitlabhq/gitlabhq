require 'spec_helper'

describe 'Projects > Snippets > User views snippets' do
  let(:project) { create(:project) }
  let!(:project_snippet) { create(:project_snippet, project: project, author: user) }
  let!(:snippet) { create(:snippet, author: user) }
  let(:snippets) { [project_snippet, snippet] } # Used by the shared examples
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_snippets_path(project))
  end

  context 'pagination' do
    before do
      create(:project_snippet, project: project, author: user)
      allow(Snippet).to receive(:default_per_page).and_return(1)

      visit project_snippets_path(project)
    end

    it_behaves_like 'paginated snippets'
  end

  it 'shows snippets' do
    expect(page).to have_content(project_snippet.title)
    expect(page).not_to have_content(snippet.title)
  end
end
