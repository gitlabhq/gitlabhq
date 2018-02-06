require 'rails_helper'

feature 'Explore Snippets' do
  let!(:public_snippet) { create(:personal_snippet, :public) }
  let!(:internal_snippet) { create(:personal_snippet, :internal) }
  let!(:private_snippet) { create(:personal_snippet, :private) }

  scenario 'User should see snippets that are not private' do
    sign_in create(:user)
    visit explore_snippets_path

    expect(page).to have_content(public_snippet.title)
    expect(page).to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end

  scenario 'External user should see only public snippets' do
    sign_in create(:user, :external)
    visit explore_snippets_path

    expect(page).to have_content(public_snippet.title)
    expect(page).not_to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end

  scenario 'Not authenticated user should see only public snippets' do
    visit explore_snippets_path

    expect(page).to have_content(public_snippet.title)
    expect(page).not_to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end
end
