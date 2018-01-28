require 'rails_helper'

feature 'User creates snippet', :js do
  include DropzoneHelper

  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit new_snippet_path
  end

  def fill_form
    fill_in 'personal_snippet_title', with: 'My Snippet Title'
    fill_in 'personal_snippet_description', with: 'My Snippet **Description**'
    page.within('.file-editor') do
      find('.ace_text-input', visible: false).send_keys 'Hello World!'
    end
  end

  scenario 'Authenticated user creates a snippet' do
    fill_form

    click_button('Create snippet')
    wait_for_requests

    expect(page).to have_content('My Snippet Title')
    page.within('.snippet-header .description') do
      expect(page).to have_content('My Snippet Description')
      expect(page).to have_selector('strong')
    end
    expect(page).to have_content('Hello World!')
  end

  scenario 'previews a snippet with file' do
    fill_in 'personal_snippet_description', with: 'My Snippet'
    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')
    find('.js-md-preview-button').click

    page.within('#new_personal_snippet .md-preview') do
      expect(page).to have_content('My Snippet')

      link = find('a.no-attachment-icon img[alt="banana_sample"]')['src']
      expect(link).to match(%r{/uploads/-/system/temp/\h{32}/banana_sample\.gif\z})

      reqs = inspect_requests { visit(link) }
      expect(reqs.first.status_code).to eq(200)
    end
  end

  scenario 'uploads a file when dragging into textarea' do
    fill_form

    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

    expect(page.find_field("personal_snippet_description").value).to have_content('banana_sample')

    click_button('Create snippet')
    wait_for_requests

    link = find('a.no-attachment-icon img[alt="banana_sample"]')['src']
    expect(link).to match(%r{/uploads/-/system/personal_snippet/#{Snippet.last.id}/\h{32}/banana_sample\.gif\z})

    reqs = inspect_requests { visit(link) }
    expect(reqs.first.status_code).to eq(200)
  end

  scenario 'validation fails for the first time' do
    fill_in 'personal_snippet_title', with: 'My Snippet Title'
    click_button('Create snippet')

    expect(page).to have_selector('#error_explanation')

    fill_form
    dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

    click_button('Create snippet')
    wait_for_requests

    expect(page).to have_content('My Snippet Title')
    page.within('.snippet-header .description') do
      expect(page).to have_content('My Snippet Description')
      expect(page).to have_selector('strong')
    end
    expect(page).to have_content('Hello World!')
    link = find('a.no-attachment-icon img[alt="banana_sample"]')['src']
    expect(link).to match(%r{/uploads/-/system/personal_snippet/#{Snippet.last.id}/\h{32}/banana_sample\.gif\z})

    reqs = inspect_requests { visit(link) }
    expect(reqs.first.status_code).to eq(200)
  end

  scenario 'Authenticated user creates a snippet with + in filename' do
    fill_in 'personal_snippet_title', with: 'My Snippet Title'
    page.within('.file-editor') do
      find(:xpath, "//input[@id='personal_snippet_file_name']").set 'snippet+file+name'
      find('.ace_text-input', visible: false).send_keys 'Hello World!'
    end

    click_button 'Create snippet'
    wait_for_requests

    expect(page).to have_content('My Snippet Title')
    expect(page).to have_content('snippet+file+name')
    expect(page).to have_content('Hello World!')
  end
end
