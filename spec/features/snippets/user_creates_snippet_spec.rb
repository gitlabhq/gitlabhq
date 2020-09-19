# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates snippet', :js do
  include DropzoneHelper
  include Spec::Support::Helpers::Features::SnippetSpecHelpers

  let_it_be(:user) { create(:user) }

  let(:title) { 'My Snippet Title' }
  let(:file_content) { 'Hello World!' }
  let(:md_description) { 'My Snippet **Description**' }
  let(:description) { 'My Snippet Description' }
  let(:created_snippet) { Snippet.last }
  let(:snippet_title_field) { 'personal_snippet_title' }

  def description_field
    find('.js-description-input').find('input,textarea')
  end

  shared_examples 'snippet creation' do
    def fill_form
      snippet_fill_in_form(title: title, content: file_content, description: md_description)
    end

    it 'Authenticated user creates a snippet' do
      fill_form

      click_button('Create snippet')
      wait_for_requests

      expect(page).to have_content(title)
      page.within(snippet_description_view_selector) do
        expect(page).to have_content(description)
        expect(page).to have_selector('strong')
      end
      expect(page).to have_content(file_content)
    end

    it 'uploads a file when dragging into textarea' do
      fill_form
      dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

      expect(snippet_description_value).to have_content('banana_sample')

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

        fill_form
        click_button('Create snippet')
        wait_for_requests
      end

      it 'renders the new page and displays the error' do
        expect(page).to have_content(error)
        expect(page).to have_content('New Snippet')

        action = find('form.snippet-form')['action']
        expect(action).to include("/snippets")
      end
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

        expect(find('.blob-content')).to have_content(file_content)
        expect(Snippet.last.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
      end
    end

    it_behaves_like 'personal snippet with references' do
      let(:container) { snippet_description_view_selector }
      let(:md_description) { references }

      subject do
        fill_form
        click_button('Create snippet')

        wait_for_requests
      end
    end
  end

  context 'Vue application' do
    let(:snippet_description_field) { 'snippet-description' }
    let(:snippet_description_view_selector) { '.snippet-header .snippet-description' }

    before do
      sign_in(user)

      visit new_snippet_path
    end

    it_behaves_like 'snippet creation'

    it 'validation fails for the first time' do
      fill_in snippet_title_field, with: title

      expect(page).not_to have_button('Create snippet')

      snippet_fill_in_form(title: title, content: file_content)
      expect(page).to have_button('Create snippet')
    end
  end

  context 'non-Vue application' do
    let(:snippet_description_field) { 'personal_snippet_description' }
    let(:snippet_description_view_selector) { '.snippet-header .description' }

    before do
      stub_feature_flags(snippets_vue: false)
      stub_feature_flags(snippets_edit_vue: false)

      sign_in(user)

      visit new_snippet_path
    end

    it_behaves_like 'snippet creation'

    it 'validation fails for the first time' do
      fill_in snippet_title_field, with: title
      click_button('Create snippet')

      expect(page).to have_selector('#error_explanation')
    end

    it 'previews a snippet with file' do
      # Click placeholder first to expand full description field
      description_field.click
      fill_in snippet_description_field, with: 'My Snippet'
      dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')
      find('.js-md-preview-button').click

      page.within('.md-preview-holder') do
        expect(page).to have_content('My Snippet')

        link = find('a.no-attachment-icon img.js-lazy-loaded[alt="banana_sample"]')['src']
        expect(link).to match(%r{/uploads/-/system/user/#{user.id}/\h{32}/banana_sample\.gif\z})

        # Adds a cache buster for checking if the image exists as Selenium is now handling the cached requests
        # not anymore as requests when they come straight from memory cache.
        reqs = inspect_requests { visit("#{link}?ran=#{SecureRandom.base64(20)}") }
        expect(reqs.first.status_code).to eq(200)
      end
    end
  end
end
