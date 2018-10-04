require 'rails_helper'

describe 'Explore Snippets' do
  let!(:public_snippet) { create(:personal_snippet, :public) }
  let!(:internal_snippet) { create(:personal_snippet, :internal) }
  let!(:private_snippet) { create(:personal_snippet, :private) }

  it 'User should see snippets that are not private' do
    sign_in create(:user)
    visit explore_snippets_path

    expect(page).to have_content(public_snippet.title)
    expect(page).to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end

  it 'External user should see only public snippets' do
    sign_in create(:user, :external)
    visit explore_snippets_path

    expect(page).to have_content(public_snippet.title)
    expect(page).not_to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end

  it 'Not authenticated user should see only public snippets' do
    visit explore_snippets_path

    expect(page).to have_content(public_snippet.title)
    expect(page).not_to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end
end
