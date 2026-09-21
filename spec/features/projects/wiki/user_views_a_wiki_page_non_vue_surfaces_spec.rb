# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project wiki > User views a wiki page non-Vue surfaces', feature_category: :wiki do
  let_it_be(:user) { create(:user) }

  let(:wiki) { create(:project_wiki, user: user, project: project) }
  let(:project) { create(:project, namespace: user.namespace, creator: user) }

  let(:wiki_page) do
    create(:wiki_page, wiki: wiki, title: 'home', content: 'home content')
  end

  before do
    sign_in(user)
  end

  context 'when a page has history' do
    before do
      wiki_page.update(message: 'updated home', content: 'updated [some link](other-page)') # rubocop:disable Rails/SaveBang -- not an ActiveRecord
    end

    it 'links to the correct diffs' do
      visit wiki_page_path(wiki, wiki_page, action: :history)

      commit1 = wiki.commit('HEAD^')
      commit2 = wiki.commit

      expect(page).to have_link('created page: home',
        href: wiki_page_path(wiki, wiki_page, version_id: commit1, action: :diff))
      expect(page).to have_link('updated home',
        href: wiki_page_path(wiki, wiki_page, version_id: commit2, action: :diff))
    end
  end

  context 'when a page has XSS in its message' do
    before do
      wiki_page.update(message: '<script>alert(true)<script>', content: 'XSS update') # rubocop:disable Rails/SaveBang -- not an ActiveRecord
    end

    it 'safely displays the message' do
      visit(wiki_page_path(wiki, wiki_page, action: :history))

      expect(page).to have_content('<script>alert(true)<script>')
    end
  end

  context 'when page has invalid content encoding' do
    let(:content) { (+'whatever').force_encoding('ISO-8859-1') }

    before do
      allow(Gitlab::EncodingHelper).to receive(:encode!).and_return(content)

      visit(wiki_page_path(wiki, wiki_page))
    end

    it 'shows error' do
      page.within(:css, '.flash-notice') do
        expect(page).to have_content(
          'The content of this page is not encoded in UTF-8. Edits can only be made via the Git repository.'
        )
      end
    end
  end
end
