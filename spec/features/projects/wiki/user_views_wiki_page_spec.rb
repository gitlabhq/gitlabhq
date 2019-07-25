# frozen_string_literal: true

require 'spec_helper'

describe 'User views a wiki page' do
  include WikiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :wiki_repo, namespace: user.namespace) }
  let(:path) { 'image.png' }
  let(:wiki_page) do
    create(:wiki_page,
           wiki: project.wiki,
           attrs: { title: 'home', content: "Look at this [image](#{path})\n\n ![alt text](#{path})" })
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when wiki is empty' do
    before do
      visit(project_wikis_path(project))
      click_link "Create your first page"

      fill_in(:wiki_title, with: 'one/two/three-test')

      page.within('.wiki-form') do
        fill_in(:wiki_content, with: 'wiki content')
        click_on('Create page')
      end
    end

    it 'shows the history of a page that has a path', :js do
      expect(current_path).to include('one/two/three-test')

      first(:link, text: 'three').click
      click_on('Page history')

      expect(current_path).to include('one/two/three-test')

      page.within(:css, '.nav-text') do
        expect(page).to have_content('History')
      end
    end

    it 'shows an old version of a page', :js do
      expect(current_path).to include('one/two/three-test')
      expect(find('.wiki-pages')).to have_content('three')

      first(:link, text: 'three').click

      expect(find('.nav-text')).to have_content('three')

      click_on('Edit')

      expect(current_path).to include('one/two/three-test')
      expect(page).to have_content('Edit Page')

      fill_in('Content', with: 'Updated Wiki Content')

      click_on('Save changes')
      click_on('Page history')

      page.within(:css, '.nav-text') do
        expect(page).to have_content('History')
      end

      find('a[href*="?version_id"]')
    end
  end

  context 'when a page does not have history' do
    before do
      visit(project_wiki_path(project, wiki_page))
    end

    it 'shows all the pages' do
      expect(page).to have_content(user.name)
      expect(find('.wiki-pages')).to have_content(wiki_page.title.capitalize)
    end

    context 'shows a file stored in a page' do
      let(:path) { upload_file_to_wiki(project, user, 'dk.png') }

      it do
        expect(page).to have_xpath("//img[@data-src='#{project.wiki.wiki_base_path}/#{path}']")
        expect(page).to have_link('image', href: "#{project.wiki.wiki_base_path}/#{path}")

        click_on('image')

        expect(current_path).to match("wikis/#{path}")
        expect(page).not_to have_xpath('/html') # Page should render the image which means there is no html involved
      end
    end

    it 'shows the creation page if file does not exist' do
      expect(page).to have_link('image', href: "#{project.wiki.wiki_base_path}/#{path}")

      click_on('image')

      expect(current_path).to match("wikis/#{path}")
      expect(page).to have_content('New Wiki Page')
      expect(page).to have_content('Create page')
    end
  end

  context 'when a page has history' do
    before do
      wiki_page.update(message: 'updated home', content: 'updated [some link](other-page)')
    end

    it 'shows the page history' do
      visit(project_wiki_path(project, wiki_page))

      expect(page).to have_selector('a.btn', text: 'Edit')

      click_on('Page history')

      expect(page).to have_content(user.name)
      expect(page).to have_content("#{user.username} created page: home")
      expect(page).to have_content('updated home')
    end

    it 'does not show the "Edit" button' do
      visit(project_wiki_path(project, wiki_page, version_id: wiki_page.versions.last.id))

      expect(page).not_to have_selector('a.btn', text: 'Edit')
    end
  end

  context 'when page has invalid content encoding' do
    let(:content) { 'whatever'.force_encoding('ISO-8859-1') }

    before do
      allow(Gitlab::EncodingHelper).to receive(:encode!).and_return(content)

      visit(project_wiki_path(project, wiki_page))
    end

    it 'does not show "Edit" button' do
      expect(page).not_to have_selector('a.btn', text: 'Edit')
    end

    it 'shows error' do
      page.within(:css, '.flash-notice') do
        expect(page).to have_content('The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.')
      end
    end
  end

  it 'opens a default wiki page', :js do
    visit(project_path(project))

    find('.shortcuts-wiki').click
    click_link "Create your first page"

    expect(page).to have_content('Home · Create Page')
  end
end
