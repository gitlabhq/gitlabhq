# frozen_string_literal: true

require 'spec_helper'

describe 'User edits snippet', :js do
  include DropzoneHelper

  let(:file_name) { 'test.rb' }
  let(:content) { 'puts "test"' }

  let(:user) { create(:user) }
  let(:snippet) { create(:personal_snippet, :public, file_name: file_name, content: content, author: user) }

  before do
    sign_in(user)

    visit edit_snippet_path(snippet)
    wait_for_requests
  end

  it 'updates the snippet' do
    fill_in 'personal_snippet_title', with: 'New Snippet Title'

    click_button('Save changes')
    wait_for_requests

    expect(page).to have_content('New Snippet Title')
  end

  it 'updates the snippet with files attached' do
    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')
    expect(page.find_field('personal_snippet_description').value).to have_content('banana_sample')

    click_button('Save changes')
    wait_for_requests

    link = find('a.no-attachment-icon img:not(.lazy)[alt="banana_sample"]')['src']
    expect(link).to match(%r{/uploads/-/system/personal_snippet/#{snippet.id}/\h{32}/banana_sample\.gif\z})
  end

  it 'updates the snippet to make it internal' do
    choose 'Internal'

    click_button 'Save changes'
    wait_for_requests

    expect(page).to have_no_xpath("//i[@class='fa fa-lock']")
    expect(page).to have_xpath("//i[@class='fa fa-shield']")
  end

  it 'updates the snippet to make it public' do
    choose 'Public'

    click_button 'Save changes'
    wait_for_requests

    expect(page).to have_no_xpath("//i[@class='fa fa-lock']")
    expect(page).to have_xpath("//i[@class='fa fa-globe']")
  end
end
