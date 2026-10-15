# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project wiki > User views wiki sidebar', :js, feature_category: :wiki do
  include WikiHelpers

  let_it_be(:user) { create(:user) }

  let(:wiki) { create(:project_wiki, user: user, project: project) }
  let(:project) { create(:project, namespace: user.namespace, creator: user) }

  before do
    sign_in(user)
  end

  context 'when there are some existing pages' do
    before do
      create(:wiki_page, wiki: wiki, title: 'home', content: 'home')
      create(:wiki_page, wiki: wiki, title: 'another', content: 'another')
    end

    context 'when there is no custom sidebar' do
      before do
        visit wiki_path(wiki)
        open_wiki_sidebar
      end

      it 'renders a default sidebar' do
        within('.wiki-sidebar') do
          expect(page).to have_content('another')
          expect(page).to have_link('View all pages')
          expect(page).to have_no_css("[data-testid='expand-pages-list']")
        end
      end

      it 'can create a custom sidebar' do
        click_on 'Add custom sidebar'
        fill_in :wiki_content, with: 'My custom sidebar'

        create_sidebar

        within('.wiki-sidebar') do
          expect(page).to have_content('My custom sidebar')
          expect(page).to have_no_content('another')
        end
      end
    end

    context 'when there is a custom sidebar' do
      before do
        create(:wiki_page, wiki: wiki, title: '_sidebar', content: 'My custom sidebar')

        visit wiki_path(wiki)
        open_wiki_sidebar
      end

      it 'renders both the custom sidebar and the default one' do
        within('.wiki-sidebar') do
          expect(page).to have_css("[data-testid='expand-pages-list']")
          expect(page).to have_content('My custom sidebar')
        end
      end

      it 'can expand list of pages in sidebar' do
        find_by_testid('expand-pages-list').click

        within('.wiki-sidebar') do
          expect(page).to have_content('another')
        end
      end

      it 'can edit the custom sidebar' do
        click_on 'Edit custom sidebar'

        expect(page).to have_field(:wiki_content, with: 'My custom sidebar')

        fill_in :wiki_content, with: 'My other custom sidebar'

        save_changes

        within('.wiki-sidebar') do
          expect(page).to have_content('My other custom sidebar')
        end
      end
    end
  end

  context 'when there are 15 existing pages' do
    before do
      create(:wiki_page, wiki: wiki, title: 'home', content: 'home')
      (1..5).each { |i| create(:wiki_page, wiki: wiki, title: "my page #{i}") }
      (6..10).each { |i| create(:wiki_page, wiki: wiki, title: "parent/my page #{i}") }
      (11..15).each { |i| create(:wiki_page, wiki: wiki, title: "grandparent/parent/my page #{i}") }
    end

    it 'shows all pages in the sidebar' do
      visit wiki_path(wiki)
      open_wiki_sidebar

      (1..15).each { |i| expect(page).to have_content("my page #{i}") }
      expect(page).to have_link('View all pages')
    end

    it 'shows all collapse buttons in the sidebar' do
      visit wiki_path(wiki)
      open_wiki_sidebar

      within('.wiki-sidebar') do
        expect(page).to have_css("[data-testid='wiki-sidebar-entry-collapser']", count: 3)
      end
    end

    it 'collapses/expands children when click collapse/expand button in the sidebar' do
      visit wiki_path(wiki)
      open_wiki_sidebar

      within('.wiki-sidebar') do
        first("[data-testid='wiki-sidebar-entry-collapser']").click
        (11..15).each { |i| expect(page).to have_no_content("my page #{i}") }
        expect(page).to have_css("[data-testid='wiki-sidebar-entry-collapser'].gl-rotate-90", count: 1)
        expect(page).to have_css("[data-testid='wiki-sidebar-entry-collapser']:not(.gl-rotate-90)", count: 1)

        first("[data-testid='wiki-sidebar-entry-collapser']").click
        (11..15).each { |i| expect(page).to have_content("my page #{i}") }
        expect(page).to have_css("[data-testid='wiki-sidebar-entry-collapser'].gl-rotate-90", count: 3)
        expect(page).to have_no_css("[data-testid='wiki-sidebar-entry-collapser']:not(.gl-rotate-90)")
      end
    end

    it 'shows create child page button when hover to the page title in the sidebar' do
      visit wiki_path(wiki)
      open_wiki_sidebar

      within('.wiki-sidebar') do
        first_wiki_list = first("[data-testid='wiki-list']")
        wiki_link = first("[data-testid='wiki-list'] a:first-of-type")['href']

        first_wiki_list.hover
        wiki_new_page_link = first(".wiki-list-create-child-button")['href']

        expect(wiki_new_page_link).to eq "#{wiki_link}/%7Bnew_page_title%7D?view=create"
      end
    end
  end
end
