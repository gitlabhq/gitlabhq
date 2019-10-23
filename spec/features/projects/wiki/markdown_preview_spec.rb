# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Wiki > User previews markdown changes', :js do
  set(:user) { create(:user) }
  set(:project) { create(:project, :wiki_repo, namespace: user.namespace) }
  let(:project_wiki) { ProjectWiki.new(project, user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
    init_home!
  end

  def init_home!
    create(:wiki_page, wiki: project.wiki, attrs: { title: 'home', content: '[some link](other-page)' })
  end

  def fill_in_content!
    page.within '.wiki-form' do
      fill_in :wiki_page_content, with: wiki_content
    end
  end

  def show_preview!
    page.within '.wiki-form' do
      click_on 'Preview'
    end
  end

  context 'when writing a new page' do
    let(:new_wiki_path) { 'a/b/c/d' }
    let(:wiki_content) { 'Some [awesome wiki](content)' }

    it 'can show a preview of markdown content' do
      visit project_wiki_pages_new_path(project, id: new_wiki_path)
      fill_in_content!
      show_preview!

      expect(page).to have_link('awesome wiki')
    end
  end

  context 'when editing an existing page' do
    let(:wiki_content) { 'Some [bemusing](content)' }
    let(:wiki_page) { create(:wiki_page, wiki: project_wiki) }

    it 'can show a preview of markdown content, when writing' do
      visit project_wiki_edit_path(project, wiki_page)
      fill_in_content!
      show_preview!

      expect(page).to have_link('bemusing')
    end
  end
end
