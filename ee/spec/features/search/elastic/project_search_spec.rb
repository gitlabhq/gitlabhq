require 'spec_helper'

describe 'Project elastic search', :js, :elastic do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.add_master(user)
    sign_in(user)
  end

  describe 'searching' do
    it 'finds issues' do
      create(:issue, project: project, title: 'Test searching for an issue')

      expect_search_result(scope: 'Issues', term: 'Test', result: 'Test searching for an issue')
    end

    it 'finds merge requests' do
      create(:merge_request, source_project: project, target_project: project, title: 'Test searching for an MR')

      expect_search_result(scope: 'Merge requests', term: 'Test', result: 'Test searching for an MR')
    end

    it 'finds milestones' do
      create(:milestone, project: project, title: 'Test searching for a milestone')

      expect_search_result(scope: 'Milestones', term: 'Test', result: 'Test searching for a milestone')
    end

    it 'finds wiki pages' do
      project.wiki.create_page('test.md', 'Test searching for a wiki page')

      expect_search_result(scope: 'Wiki', term: 'Test', result: 'Test searching for a wiki page')
    end

    it 'finds notes' do
      create(:note, project: project, note: 'Test searching for a note')

      search(scope: 'Comments', term: 'Test')

      expect(page).to have_content(/showing (\d+) - (\d+) of (\d+) notes/i)
      expect(page).to have_content('Test searching for a note')
    end

    it 'finds commits' do
      project.repository.index_commits

      search(scope: 'Commits', term: 'initial')

      expect(page).to have_content(/showing (\d+) - (\d+) of (\d+) commits/i)
      expect(page).to have_content('Initial commit')
    end

    it 'finds blobs' do
      project.repository.index_blobs

      search(scope: 'Code', term: 'def')

      expect(page).to have_content(/showing (\d+) - (\d+) of (\d+) blobs/i)
      expect(page).to have_content('def username_regex')
    end
  end

  def search(scope:, term:)
    visit project_path(project)

    fill_in('search', with: term)
    find('#search').native.send_keys(:enter)

    page.within '.search-filter' do
      click_link scope
    end
  end

  def expect_search_result(scope:, term:, result:)
    search(scope: scope, term: term)

    expect(page).to have_content(/showing (\d+) - (\d+) of (\d+) #{Regexp.escape(scope)}/i)
    expect(page).to have_content(result)
  end
end
