require 'spec_helper'

describe "Search", feature: true  do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:issue) { create(:issue, project: project, assignee: user) }
  let!(:issue2) { create(:issue, project: project, author: user) }

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

  describe 'Right header search field', feature: true do
    it 'allows enter key to search', js: true do
      visit namespace_project_path(project.namespace, project)
      fill_in 'search', with: 'gitlab'
      find('#search').native.send_keys(:enter)

      page.within '.title' do
        expect(page).to have_content 'Search'
      end
    end

    describe 'Search in project page' do
      before do
        visit namespace_project_path(project.namespace, project)
      end

      it 'top right search form is present' do
        expect(page).to have_selector('#search')
      end

      it 'top right search form contains location badge' do
        expect(page).to have_selector('.has-location-badge')
      end

      context 'clicking the search field', js: true do
        it 'should show category search dropdown' do
          page.find('#search').click

          expect(page).to have_selector('.dropdown-header', text: /#{project.name}/i)
        end
      end

      context 'click the links in the category search dropdown', js: true do
        before do
          page.find('#search').click
        end

        it 'should take user to her issues page when issues assigned is clicked' do
          find('.dropdown-menu').click_link 'Issues assigned to me'
          sleep 2

          expect(page).to have_selector('.issues-holder')
          expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
        end

        it 'should take user to her issues page when issues authored is clicked' do
          find('.dropdown-menu').click_link "Issues I've created"
          sleep 2

          expect(page).to have_selector('.issues-holder')
          expect(find('.js-author-search .dropdown-toggle-text')).to have_content(user.name)
        end

        it 'should take user to her MR page when MR assigned is clicked' do
          find('.dropdown-menu').click_link 'Merge requests assigned to me'
          sleep 2

          expect(page).to have_selector('.merge-requests-holder')
          expect(find('.js-assignee-search .dropdown-toggle-text')).to have_content(user.name)
        end

        it 'should take user to her MR page when MR authored is clicked' do
          find('.dropdown-menu').click_link "Merge requests I've created"
          sleep 2

          expect(page).to have_selector('.merge-requests-holder')
          expect(find('.js-author-search .dropdown-toggle-text')).to have_content(user.name)
        end
      end

      context 'entering text into the search field', js: true do
        before do
          page.within '.search-input-wrap' do
            fill_in "search", with: project.name[0..3]
          end
        end

        it 'should not display the category search dropdown' do
          expect(page).not_to have_selector('.dropdown-header', text: /#{project.name}/i)
        end
      end
    end
  end
end
