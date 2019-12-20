# frozen_string_literal: true

require 'spec_helper'

describe 'User Snippets' do
  let(:author) { create(:user) }
  let!(:public_snippet) { create(:personal_snippet, :public, author: author, title: "This is a public snippet") }
  let!(:internal_snippet) { create(:personal_snippet, :internal, author: author, title: "This is an internal snippet") }
  let!(:private_snippet) { create(:personal_snippet, :private, author: author, title: "This is a private snippet") }

  before do
    sign_in author
    visit dashboard_snippets_path
  end

  it 'View all of my snippets' do
    expect(page).to have_link(public_snippet.title, href: snippet_path(public_snippet))
    expect(page).to have_link(internal_snippet.title, href: snippet_path(internal_snippet))
    expect(page).to have_link(private_snippet.title, href: snippet_path(private_snippet))
  end

  it 'View my public snippets' do
    page.within('.snippet-scope-menu') do
      click_link "Public"
    end

    expect(page).to have_content(public_snippet.title)
    expect(page).not_to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end

  it 'View my internal snippets' do
    page.within('.snippet-scope-menu') do
      click_link "Internal"
    end

    expect(page).not_to have_content(public_snippet.title)
    expect(page).to have_content(internal_snippet.title)
    expect(page).not_to have_content(private_snippet.title)
  end

  it 'View my private snippets' do
    page.within('.snippet-scope-menu') do
      click_link "Private"
    end

    expect(page).not_to have_content(public_snippet.title)
    expect(page).not_to have_content(internal_snippet.title)
    expect(page).to have_content(private_snippet.title)
  end
end
