# frozen_string_literal: true

require 'spec_helper'

describe 'User views wiki pages' do
  include WikiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :wiki_repo, namespace: user.namespace) }

  let!(:wiki_page1) do
    create(:wiki_page, wiki: project.wiki, attrs: { title: '3 home', content: '3' })
  end
  let!(:wiki_page2) do
    create(:wiki_page, wiki: project.wiki, attrs: { title: '1 home', content: '1' })
  end
  let!(:wiki_page3) do
    create(:wiki_page, wiki: project.wiki, attrs: { title: '2 home', content: '2' })
  end

  let(:pages) do
    page.find('.wiki-pages-list').all('li').map { |li| li.find('a') }
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit(project_wikis_pages_path(project))
  end

  context 'ordered by title' do
    let(:pages_ordered_by_title) { [wiki_page2, wiki_page3, wiki_page1] }

    context 'asc' do
      it 'pages are displayed in direct order' do
        pages.each.with_index do |page_title, index|
          expect(page_title.text).to eq(pages_ordered_by_title[index].title)
        end
      end
    end

    context 'desc' do
      before do
        page.within('.wiki-sort-dropdown') do
          page.find('.rspec-reverse-sort').click
        end
      end

      it 'pages are displayed in reversed order' do
        pages.reverse_each.with_index do |page_title, index|
          expect(page_title.text).to eq(pages_ordered_by_title[index].title)
        end
      end
    end
  end

  context 'ordered by created_at' do
    let(:pages_ordered_by_created_at) { [wiki_page1, wiki_page2, wiki_page3] }

    before do
      page.within('.wiki-sort-dropdown') do
        click_button('Title')
        click_link('Created date')
      end
    end

    context 'asc' do
      it 'pages are displayed in direct order' do
        pages.each.with_index do |page_title, index|
          expect(page_title.text).to eq(pages_ordered_by_created_at[index].title)
        end
      end
    end

    context 'desc' do
      before do
        page.within('.wiki-sort-dropdown') do
          page.find('.rspec-reverse-sort').click
        end
      end

      it 'pages are displayed in reversed order' do
        pages.reverse_each.with_index do |page_title, index|
          expect(page_title.text).to eq(pages_ordered_by_created_at[index].title)
        end
      end
    end
  end
end
