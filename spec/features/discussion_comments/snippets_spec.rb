# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Thread Comments Snippet', :js, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'with project snippets' do
    let_it_be(:project) do
      create(:project).tap do |p|
        p.add_maintainer(user)
      end
    end

    let_it_be(:snippet) { create(:project_snippet, :private, :repository, project: project, author: user) }

    before do
      visit project_snippet_path(project, snippet)
    end

    it_behaves_like 'thread comments for commit and snippet', 'snippet'
  end

  context 'with personal snippets' do
    let_it_be(:snippet) { create(:personal_snippet, :private, :repository, author: user) }

    before do
      visit snippet_path(snippet)
    end

    it_behaves_like 'thread comments for commit and snippet', 'snippet'
  end
end
