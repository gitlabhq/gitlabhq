# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Private Snippets', :js, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:private_snippet) { create(:personal_snippet, :repository, :private, author: user) }
  let(:content) { private_snippet.blobs.first.data.strip! }

  before do
    sign_in(user)
  end

  it 'private Snippet renders for creator' do
    visit snippet_path(private_snippet)
    wait_for_requests

    expect(page).to have_content(content)
    expect(page).not_to have_css('.js-embed-btn')
    expect(page).not_to have_css('.js-share-btn')
  end
end
