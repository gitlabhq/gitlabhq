# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits snippet', :js, feature_category: :source_code_management do
  include DropzoneHelper
  include Features::SnippetSpecHelpers

  let_it_be(:file_name) { 'test.rb' }
  let_it_be(:content) { 'puts "test"' }
  let_it_be(:user) { create(:user) }
  let_it_be(:snippet, reload: true) { create(:personal_snippet, :repository, :public, file_name: file_name, content: content, author: user) }

  before do
    sign_in(user)

    visit edit_snippet_path(snippet)
    wait_for_all_requests
  end

  it 'displays the snippet blob path and content' do
    blob = snippet.blobs.first

    aggregate_failures do
      expect(snippet_get_first_blob_path).to eq blob.path
      expect(snippet_get_first_blob_value).to have_content(blob.data.strip)
    end
  end

  it 'updates the snippet' do
    snippet_fill_in_title('New Snippet Title')
    expect(page).not_to have_selector('.gl-spinner')

    click_button('Save changes')
    wait_for_requests

    expect(page).to have_content('New Snippet Title')
  end

  it 'updates the snippet with files attached' do
    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')
    expect(snippet_description_value).to have_content('banana_sample')

    click_button('Save changes')
    wait_for_requests

    link = find('a.no-attachment-icon img:not(.lazy)[alt="banana_sample"]')['src']
    expect(link).to match(%r{/uploads/-/system/personal_snippet/#{snippet.id}/\h{32}/banana_sample\.gif\z})
  end

  it 'updates the snippet to make it internal' do
    snippet_fill_in_visibility('Internal')

    click_button 'Save changes'
    wait_for_requests

    expect(page).to have_no_selector('[data-testid="lock-icon"]')
    expect(page).to have_selector('[data-testid="shield-icon"]')
  end

  it 'updates the snippet to make it public' do
    snippet_fill_in_visibility('Public')

    click_button 'Save changes'
    wait_for_requests

    expect(page).to have_no_selector('[data-testid="lock-icon"]')
    expect(page).to have_selector('[data-testid="earth-icon"]')
  end

  context 'when the git operation fails' do
    before do
      allow_next_instance_of(Snippets::UpdateService) do |instance|
        allow(instance).to receive(:create_commit).and_raise(StandardError, 'Error Message')
      end

      snippet_fill_in_form(title: 'New Snippet Title', file_name: 'new_file_name')

      click_button('Save changes')
    end

    it 'renders edit page and displays the error' do
      expect(page.find('.flash-container')).to have_content('Error updating the snippet - Error Message')
      expect(page).to have_content('Edit snippet')
    end
  end
end
