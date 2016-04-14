require 'spec_helper'

describe "Search", feature: true  do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    login_with(user)
    project.team << [user, :reporter]
    visit search_path
  end

  it 'top right search form is not present' do
    expect(page).not_to have_selector('.search')
  end

  describe 'searching for Projects' do
    it 'finds a project' do
      page.within '.search-holder' do
        fill_in "search", with: project.name[0..3]
        click_button "Search"
      end

      expect(page).to have_content project.name
    end
  end

  context 'search for comments' do
    it 'finds a snippet' do
      snippet = create(:project_snippet, :private, project: project, author: user, title: 'Some title')
      note = create(:note,
                    noteable: snippet,
                    author: user,
                    note: 'Supercalifragilisticexpialidocious',
                    project: project)
      # Must visit project dashboard since global search won't search
      # everything (e.g. comments, snippets, etc.)
      visit namespace_project_path(project.namespace, project)

      page.within '.search' do
        fill_in 'search', with: note.note
        click_button 'Go'
      end

      click_link 'Comments'

      expect(page).to have_link(snippet.title)
    end
  end
end
