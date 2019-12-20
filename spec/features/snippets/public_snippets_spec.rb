# frozen_string_literal: true

require 'spec_helper'

describe 'Public Snippets', :js do
  before do
    stub_feature_flags(snippets_vue: false)
  end

  it 'Unauthenticated user should see public snippets' do
    public_snippet = create(:personal_snippet, :public)

    visit snippet_path(public_snippet)
    wait_for_requests

    expect(page).to have_content(public_snippet.content)
    expect(page).to have_css('.js-embed-btn', visible: false)
    expect(page).to have_css('.js-share-btn', visible: false)
    expect(page.find('.js-snippet-url-area')).to be_readonly
  end

  it 'Unauthenticated user should see raw public snippets' do
    public_snippet = create(:personal_snippet, :public)

    visit raw_snippet_path(public_snippet)

    expect(page).to have_content(public_snippet.content)
  end
end
