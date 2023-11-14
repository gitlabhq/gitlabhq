# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Snippets > Project snippet', :js, feature_category: :source_code_management do
  let_it_be(:author) { create(:author) }
  let_it_be(:project) do
    create(:project, :public, creator: author).tap do |p|
      p.add_maintainer(author)
    end
  end

  let_it_be(:snippet) { create(:project_snippet, :public, :repository, project: project, author: author) }
  let(:anchor) { nil }
  let(:file_path) { 'files/ruby/popen.rb' }

  def visit_page
    visit project_snippet_path(project, snippet, anchor: anchor)
  end

  before do
    # rubocop: disable RSpec/AnyInstanceOf -- TODO: The usage of let_it_be forces us
    allow_any_instance_of(Snippet).to receive(:blobs)
      .and_return([snippet.repository.blob_at('master', file_path)])
    # rubocop: enable RSpec/AnyInstanceOf
  end

  context 'when signed in' do
    before do
      sign_in(user)
      visit_page
    end

    context 'as project member' do
      let(:user) { author }

      it_behaves_like 'show and render proper snippet blob'
      it_behaves_like 'does show New Snippet button'
    end

    context 'as external user' do
      let_it_be(:user) { create(:user, :external) }

      it_behaves_like 'show and render proper snippet blob'
      it_behaves_like 'does not show New Snippet button'
    end

    context 'as another user' do
      let_it_be(:user) { create(:user) }

      it_behaves_like 'show and render proper snippet blob'
      it_behaves_like 'does not show New Snippet button'
    end
  end

  context 'when unauthenticated' do
    before do
      visit_page
    end

    it_behaves_like 'show and render proper snippet blob'
    it_behaves_like 'does not show New Snippet button'
  end
end
