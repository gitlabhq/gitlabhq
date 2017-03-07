require 'spec_helper'

describe "Search", feature: true  do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:issue) { create(:issue, project: project, assignee: user) }
  let!(:issue2) { create(:issue, project: project, author: user) }

  before do
    login_with(user)
    project.team << [user, :reporter]
    visit search_path
  end

  it 'does not show top right search form' do
    expect(page).not_to have_selector('.search')
  end

  context 'search filters', js: true do
    let(:group) { create(:group) }

    before do
      group.add_owner(user)
    end

    it 'shows group name after filtering' do
      find('.js-search-group-dropdown').click
      wait_for_ajax

      page.within '.search-holder' do
        click_link group.name
      end

      expect(find('.js-search-group-dropdown')).to have_content(group.name)
    end

    it 'shows project name after filtering' do
      page.within('.project-filter') do
        find('.js-search-project-dropdown').click
        wait_for_ajax

        click_link project.name_with_namespace
      end

      expect(find('.js-search-project-dropdown')).to have_content(project.name_with_namespace)
    end
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
    context 'when comment belongs to a invalid commit' do
      let(:note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'Bug here') }

      before { note.update_attributes(commit_id: 12345678) }

      it 'finds comment' do
        visit namespace_project_path(project.namespace, project)

        page.within '.search' do
          fill_in 'search', with: note.note
          click_button 'Go'
        end

        click_link 'Comments'

        expect(page).to have_text("Commit deleted")
        expect(page).to have_text("12345678")
      end
    end

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

    it 'finds a commit' do
      visit namespace_project_path(project.namespace, project)

      page.within '.search' do
        fill_in 'search', with: 'add'
        click_button 'Go'
      end

      click_link "Commits"

      expect(page).to have_selector('.commit-row-description')
    end

    it 'finds a code' do
      visit namespace_project_path(project.namespace, project)

      page.within '.search' do
        fill_in 'search', with: 'def'
        click_button 'Go'
      end

      click_link "Code"

      expect(page).to have_selector('.file-content .code')
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

      it 'shows top right search form' do
        expect(page).to have_selector('#search')
      end

      it 'contains location badge in top right search form' do
        expect(page).to have_selector('.has-location-badge')
      end

      context 'clicking the search field', js: true do
        it 'shows category search dropdown' do
          page.find('#search').click

          expect(page).to have_selector('.dropdown-header', text: /#{project.name}/i)
        end
      end

      context 'click the links in the category search dropdown', js: true do
        before do
          page.find('#search').click
        end

        it 'takes user to her issues page when issues assigned is clicked' do
          find('.dropdown-menu').click_link 'Issues assigned to me'
          sleep 2

          expect(page).to have_selector('.filtered-search')
          expect(find('.filtered-search').value).to eq("assignee:@#{user.username}")
        end

        it 'takes user to her issues page when issues authored is clicked' do
          find('.dropdown-menu').click_link "Issues I've created"
          sleep 2

          expect(page).to have_selector('.filtered-search')
          expect(find('.filtered-search').value).to eq("author:@#{user.username}")
        end

        it 'takes user to her MR page when MR assigned is clicked' do
          find('.dropdown-menu').click_link 'Merge requests assigned to me'
          sleep 2

          expect(page).to have_selector('.merge-requests-holder')
          expect(find('.filtered-search').value).to eq("assignee:@#{user.username}")
        end

        it 'takes user to her MR page when MR authored is clicked' do
          find('.dropdown-menu').click_link "Merge requests I've created"
          sleep 2

          expect(page).to have_selector('.merge-requests-holder')
          expect(find('.filtered-search').value).to eq("author:@#{user.username}")
        end
      end

      context 'entering text into the search field', js: true do
        before do
          page.within '.search-input-wrap' do
            fill_in "search", with: project.name[0..3]
          end
        end

        it 'does not display the category search dropdown' do
          expect(page).not_to have_selector('.dropdown-header', text: /#{project.name}/i)
        end
      end
    end
  end

  describe 'search for commits' do
    before do
      visit search_path(project_id: project.id)
    end

    it 'redirects to commit page when search by sha and only commit found' do
      fill_in 'search', with: '6d394385cf567f80a8fd85055db1ab4c5295806f'

      click_button 'Search'

      expect(page).to have_current_path(namespace_project_commit_path(project.namespace, project, '6d394385cf567f80a8fd85055db1ab4c5295806f'))
    end

    it 'redirects to single commit regardless of query case' do
      fill_in 'search', with: '6D394385cf'

      click_button 'Search'

      expect(page).to have_current_path(namespace_project_commit_path(project.namespace, project, '6d394385cf567f80a8fd85055db1ab4c5295806f'))
    end

    it 'holds on /search page when the only commit is found by message' do
      create_commit('Message referencing another sha: "deadbeef" ', project, user, 'master')

      fill_in 'search', with: 'deadbeef'
      click_button 'Search'

      expect(page).to have_current_path('/search', only_path: true)
    end

    it 'shows multiple matching commits' do
      fill_in 'search', with: 'See merge request'

      click_button 'Search'
      click_link 'Commits'

      expect(page).to have_selector('.commit-row-description', count: 9)
    end
  end
end
