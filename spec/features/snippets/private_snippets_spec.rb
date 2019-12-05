# frozen_string_literal: true

require 'spec_helper'

describe 'Private Snippets', :js do
  let(:user) { create(:user) }

  before do
    stub_feature_flags(snippets_vue: false)
    sign_in(user)
  end

  it 'Private Snippet renders for creator' do
    private_snippet = create(:personal_snippet, :private, author: user)

    visit snippet_path(private_snippet)
    wait_for_requests

    expect(page).to have_content(private_snippet.content)
    expect(page).not_to have_css('.js-embed-btn')
    expect(page).not_to have_css('.js-share-btn')
  end
end
