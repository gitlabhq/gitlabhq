# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Public Snippets', :js, feature_category: :source_code_management do
  let(:public_snippet) { create(:personal_snippet, :public, :repository) }
  let(:content) { public_snippet.blobs.first.data.strip! }

  it 'unauthenticated user should see public snippets' do
    url = Gitlab::UrlBuilder.build(public_snippet)

    visit snippet_path(public_snippet)
    wait_for_requests

    expect(page).to have_content(content)
    click_button('Code')
    expect(page).to have_field('Embed', readonly: true, with: "<script src=\"#{url}.js\"></script>")
    expect(page).to have_field('Share', readonly: true, with: url)
  end

  it 'unauthenticated user should see raw public snippets' do
    visit raw_snippet_path(public_snippet)

    expect(page).to have_content(content)
  end
end
