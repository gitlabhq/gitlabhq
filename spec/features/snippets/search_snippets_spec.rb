# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Search Snippets', :js, feature_category: :global_search do
  it 'user searches for snippets by title' do
    user = create(:user)
    public_snippet = create(:personal_snippet, :public, title: 'Beginning and Middle')
    private_snippet = create(:personal_snippet, :private, title: 'Middle and End', author: user)

    sign_in user
    visit dashboard_snippets_path

    submit_search('Middle')
    select_search_scope(_("Snippets"))

    expect(page).to have_link(public_snippet.title)
    expect(page).to have_link(private_snippet.title)
  end
end
