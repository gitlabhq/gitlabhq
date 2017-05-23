require 'rails_helper'

feature 'Create Snippet', :js, feature: true do
  before do
    login_as :user
    visit new_snippet_path
  end

  scenario 'Authenticated user creates a snippet' do
    fill_in 'personal_snippet_title', with: 'My Snippet Title'
    page.within('.file-editor') do
      find('.ace_editor').native.send_keys 'Hello World!'
    end

    click_button 'Create snippet'
    wait_for_requests

    expect(page).to have_content('My Snippet Title')
    expect(page).to have_content('Hello World!')
  end

  scenario 'Authenticated user creates a snippet with + in filename' do
    fill_in 'personal_snippet_title', with: 'My Snippet Title'
    page.within('.file-editor') do
      find(:xpath, "//input[@id='personal_snippet_file_name']").set 'snippet+file+name'
      find('.ace_editor').native.send_keys 'Hello World!'
    end

    click_button 'Create snippet'
    wait_for_requests

    expect(page).to have_content('My Snippet Title')
    expect(page).to have_content('snippet+file+name')
    expect(page).to have_content('Hello World!')
  end
end
