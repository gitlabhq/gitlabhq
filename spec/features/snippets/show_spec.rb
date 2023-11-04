# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Snippet', :js, feature_category: :source_code_management do
  let_it_be(:owner) { create(:user) }
  let_it_be(:snippet) { create(:personal_snippet, :public, :repository, author: owner) }
  let(:anchor) { nil }
  let(:file_path) { 'files/ruby/popen.rb' }

  before do
    # rubocop: disable RSpec/AnyInstanceOf -- TODO: The usage of let_it_be forces us
    allow_any_instance_of(Snippet).to receive(:blobs)
      .and_return([snippet.repository.blob_at('master', file_path)])
    # rubocop: enable RSpec/AnyInstanceOf
  end

  def visit_page
    visit snippet_path(snippet, anchor: anchor)
  end

  context 'when signed in' do
    before do
      sign_in(user)
      visit_page
    end

    context 'as the snippet owner' do
      let(:user) { owner }

      it_behaves_like 'show and render proper snippet blob'
      it_behaves_like 'does show New Snippet button'
      it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_snippets_path, :snippets
    end

    context 'as external user' do
      let_it_be(:user) { create(:user, :external) }

      it_behaves_like 'show and render proper snippet blob'
      it_behaves_like 'does not show New Snippet button'
      it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_snippets_path, :snippets
    end

    context 'as another user' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'show and render proper snippet blob'
      it_behaves_like 'does show New Snippet button'
      it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_snippets_path, :snippets
    end
  end

  context 'when unauthenticated' do
    before do
      visit_page
    end

    it_behaves_like 'show and render proper snippet blob'
    it_behaves_like 'does not show New Snippet button'

    it 'shows the "Explore" sidebar' do
      expect(page).to have_css('#super-sidebar-context-header', text: 'Explore')
    end
  end
end
