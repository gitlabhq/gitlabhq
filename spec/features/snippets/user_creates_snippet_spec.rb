# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates snippet', :js do
  include DropzoneHelper

  let_it_be(:user) { create(:user) }

  let(:title) { 'My Snippet Title' }
  let(:file_content) { 'Hello World!' }
  let(:md_description) { 'My Snippet **Description**' }
  let(:description) { 'My Snippet Description' }
  let(:created_snippet) { Snippet.last }

  before do
    stub_feature_flags(snippets_vue: false)
    stub_feature_flags(snippets_edit_vue: false)
    sign_in(user)
  end

  def description_field
    find('.js-description-input').find('input,textarea')
  end

  def fill_form
    fill_in 'personal_snippet_title', with: title

    # Click placeholder first to expand full description field
    description_field.click
    fill_in 'personal_snippet_description', with: md_description

    page.within('.file-editor') do
      el = find('.inputarea')
      el.send_keys file_content
    end
  end

  it 'Authenticated user creates a snippet' do
    visit new_snippet_path

    fill_form

    click_button('Create snippet')
    wait_for_requests

    expect(page).to have_content(title)
    page.within('.snippet-header .description') do
      expect(page).to have_content(description)
      expect(page).to have_selector('strong')
    end
    expect(page).to have_content(file_content)
  end

  it 'previews a snippet with file' do
    visit new_snippet_path

    # Click placeholder first to expand full description field
    description_field.click
    fill_in 'personal_snippet_description', with: 'My Snippet'
    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')
    find('.js-md-preview-button').click

    page.within('#new_personal_snippet .md-preview-holder') do
      expect(page).to have_content('My Snippet')

      link = find('a.no-attachment-icon img.js-lazy-loaded[alt="banana_sample"]')['src']
      expect(link).to match(%r{/uploads/-/system/user/#{user.id}/\h{32}/banana_sample\.gif\z})

      # Adds a cache buster for checking if the image exists as Selenium is now handling the cached requests
      # not anymore as requests when they come straight from memory cache.
      reqs = inspect_requests { visit("#{link}?ran=#{SecureRandom.base64(20)}") }
      expect(reqs.first.status_code).to eq(200)
    end
  end

  it 'uploads a file when dragging into textarea' do
    visit new_snippet_path

    fill_form

    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

    expect(page.find_field("personal_snippet_description").value).to have_content('banana_sample')

    click_button('Create snippet')
    wait_for_requests

    link = find('a.no-attachment-icon img.js-lazy-loaded[alt="banana_sample"]')['src']
    expect(link).to match(%r{/uploads/-/system/personal_snippet/#{Snippet.last.id}/\h{32}/banana_sample\.gif\z})

    reqs = inspect_requests { visit("#{link}?ran=#{SecureRandom.base64(20)}") }
    expect(reqs.first.status_code).to eq(200)
  end

  context 'when the git operation fails' do
    let(:error) { 'Error creating the snippet' }

    before do
      allow_next_instance_of(Snippets::CreateService) do |instance|
        allow(instance).to receive(:create_commit).and_raise(StandardError, error)
      end

      visit new_snippet_path

      fill_form

      click_button('Create snippet')
      wait_for_requests
    end

    it 'renders the new page and displays the error' do
      expect(page).to have_content(error)
      expect(page).to have_content('New Snippet')

      action = find('form.snippet-form')['action']
      expect(action).to match(%r{/snippets\z})
    end
  end

  it 'validation fails for the first time' do
    visit new_snippet_path

    fill_in 'personal_snippet_title', with: title
    click_button('Create snippet')

    expect(page).to have_selector('#error_explanation')
  end

  context 'when snippets default visibility level is restricted' do
    before do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PRIVATE],
                              default_snippet_visibility: Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'creates a snippet using the lowest available visibility level as default' do
      visit new_snippet_path

      fill_form

      click_button('Create snippet')
      wait_for_requests

      expect(created_snippet.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
    end
  end
end
