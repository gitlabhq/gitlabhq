require 'spec_helper'

feature 'Group elastic search', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }

  def choose_group(group)
    find('.js-search-group-dropdown').click
    wait_for_requests

    page.within '.search-holder' do
      click_link group.name
    end
  end

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index

    project.add_master(user)
    group.add_owner(user)

    sign_in(user)
  end

  after do
    Gitlab::Elastic::Helper.delete_index
    stub_ee_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  describe 'issue search' do
    before do
      create(:issue, project: project, title: 'chosen issue title')

      Gitlab::Elastic::Helper.refresh_index
    end

    it 'finds the issue' do
      visit search_path

      choose_group group
      fill_in 'search', with: 'chosen'
      find('.btn-search').click

      select_filter('Issues')
      expect(page).to have_content('chosen issue title')
    end
  end

  describe 'blob search' do
    before do
      project.repository.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    it 'finds files' do
      visit search_path

      choose_group group
      fill_in 'search', with: 'def'
      find('.btn-search').click

      select_filter('Code')

      expect(page).to have_selector('.file-content .code')
    end
  end

  describe 'wiki search' do
    let(:wiki) { ProjectWiki.new(project, user) }

    before do
      wiki.create_page('test.md', '# term')
      wiki.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    it "finds pages" do
      visit search_path

      choose_group group
      fill_in "search", with: "term"
      find('.btn-search').click

      select_filter("Wiki")

      expect(page).to have_selector('.file-content .code')

      expect(page).to have_selector("span.line[lang='markdown']")
    end
  end

  describe 'commit search' do
    before do
      project.repository.index_commits
      Gitlab::Elastic::Helper.refresh_index
    end

    it 'finds commits' do
      visit search_path

      choose_group group
      fill_in 'search', with: 'add'
      find('.btn-search').click

      select_filter('Commits')

      expect(page).to have_selector('.commit-list > .commit')
    end
  end
end
