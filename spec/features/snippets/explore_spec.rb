require 'rails_helper'

feature 'Explore Snippets', feature: true do
  scenario 'User should see snippets that are not private' do
    public_snippet = create(:personal_snippet, :public)
    internal_snippet = create(:personal_snippet, :internal)
    private_snippet = create(:personal_snippet, :private)

    login_as create(:user)
    visit explore_snippets_path

    expect(page).to have_content(public_snippet.title)
    expect(page).to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end
end
