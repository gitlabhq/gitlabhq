require 'spec_helper'

RSpec.describe 'admin manage applications' do
  before do
    sign_in(create(:admin))
  end

  it do
    visit admin_applications_path

    click_on 'New application'
    expect(page).to have_content('New application')

    fill_in :doorkeeper_application_name, with: 'test'
    fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
    click_on 'Submit'
    expect(page).to have_content('Application: test')
    expect(page).to have_content('Application Id')
    expect(page).to have_content('Secret')

    click_on 'Edit'
    expect(page).to have_content('Edit application')

    fill_in :doorkeeper_application_name, with: 'test_changed'
    click_on 'Submit'
    expect(page).to have_content('test_changed')
    expect(page).to have_content('Application Id')
    expect(page).to have_content('Secret')

    visit admin_applications_path
    page.within '.oauth-applications' do
      click_on 'Destroy'
    end
    expect(page.find('.oauth-applications')).not_to have_content('test_changed')
  end
end
