# frozen_string_literal: true

require 'spec_helper'

describe 'User deletes snippet' do
  let(:user) { create(:user) }
  let(:content) { 'puts "test"' }
  let(:snippet) { create(:personal_snippet, :public, content: content, author: user) }

  before do
    sign_in(user)

    stub_feature_flags(snippets_vue: false)

    visit snippet_path(snippet)
  end

  it 'deletes the snippet' do
    first(:link, 'Delete').click

    expect(page).not_to have_content(snippet.title)
  end
end
