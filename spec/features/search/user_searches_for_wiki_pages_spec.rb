require 'spec_helper'

describe 'User searches for wiki pages', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:wiki_page) { create(:wiki_page, wiki: project.wiki, attrs: { title: 'test_wiki', content: 'Some Wiki content' }) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(search_path)
  end

  include_examples 'top right search form'

  it 'finds a page' do
    find('.js-search-project-dropdown').click

    page.within('.project-filter') do
      click_link(project.full_name)
    end

    fill_in('dashboard_search', with: 'content')
    find('.btn-search').click

    page.within('.search-filter') do
      click_link('Wiki')
    end

    page.within('.results') do
      expect(find(:css, '.search-results')).to have_link(wiki_page.title)
    end
  end
end
