require 'spec_helper'

describe 'Dashboard snippets' do
  context 'when the project has snippets' do
    let(:project) { create(:project, :public) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.owner, project: project) }
    before do
      allow(Snippet).to receive(:default_per_page).and_return(1)
      sign_in(project.owner)
      visit dashboard_snippets_path
    end

    it_behaves_like 'paginated snippets'
  end

  context 'filtering by visibility' do
    let(:user) { create(:user) }
    let!(:snippets) do
      [
        create(:personal_snippet, :public, author: user),
        create(:personal_snippet, :internal, author: user),
        create(:personal_snippet, :private, author: user),
        create(:personal_snippet, :public)
      ]
    end

    before do
      sign_in(user)

      visit dashboard_snippets_path
    end

    it 'contains all snippets of logged user' do
      expect(page).to have_selector('.snippet-row', count: 3)

      expect(page).to have_content(snippets[0].title)
      expect(page).to have_content(snippets[1].title)
      expect(page).to have_content(snippets[2].title)
    end

    it 'contains all private snippets of logged user when clicking on private' do
      click_link('Private')

      expect(page).to have_selector('.snippet-row', count: 1)
      expect(page).to have_content(snippets[2].title)
    end

    it 'contains all internal snippets of logged user when clicking on internal' do
      click_link('Internal')

      expect(page).to have_selector('.snippet-row', count: 1)
      expect(page).to have_content(snippets[1].title)
    end

    it 'contains all public snippets of logged user when clicking on public' do
      click_link('Public')

      expect(page).to have_selector('.snippet-row', count: 1)
      expect(page).to have_content(snippets[0].title)
    end
  end
end
