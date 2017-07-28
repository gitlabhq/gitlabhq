require 'rails_helper'

feature 'User Snippets' do
  let(:author) { create(:user) }
  let!(:public_snippet) { create(:personal_snippet, :public, author: author, title: "This is a public snippet") }
  let!(:internal_snippet) { create(:personal_snippet, :internal, author: author, title: "This is an internal snippet") }
  let!(:private_snippet) { create(:personal_snippet, :private, author: author, title: "This is a private snippet") }

  background do
    sign_in author
    visit dashboard_snippets_path
  end

  scenario 'View all of my snippets' do
    expect(page).to have_content(public_snippet.title)
    expect(page).to have_content(internal_snippet.title)
    expect(page).to have_content(private_snippet.title)
  end

  scenario 'View my public snippets' do
    page.within('.snippet-scope-menu') do
      click_link "Public"
    end

    expect(page).to have_content(public_snippet.title)
    expect(page).not_to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end

  scenario 'View my internal snippets' do
    page.within('.snippet-scope-menu') do
      click_link "Internal"
    end

    expect(page).not_to have_content(public_snippet.title)
    expect(page).to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end

  scenario 'View my private snippets' do
    page.within('.snippet-scope-menu') do
      click_link "Private"
    end

    expect(page).not_to have_content(public_snippet.title)
    expect(page).not_to have_content(internal_snippet.title)
    expect(page).to have_content(private_snippet.title)
  end
end
