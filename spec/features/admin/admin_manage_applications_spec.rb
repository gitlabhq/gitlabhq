# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin manage applications' do
  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  it 'creates new oauth application' do
    visit admin_applications_path

    click_on 'New application'
    expect(page).to have_content('New application')

    fill_in :doorkeeper_application_name, with: 'test'
    fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
    check :doorkeeper_application_trusted
    check :doorkeeper_application_scopes_read_user
    click_on 'Submit'
    expect(page).to have_content('Application: test')
    expect(page).to have_content('Application ID')
    expect(page).to have_content('Secret')
    expect(page).to have_content('Trusted Y')
    expect(page).to have_content('Confidential Y')

    click_on 'Edit'
    expect(page).to have_content('Edit application')

    fill_in :doorkeeper_application_name, with: 'test_changed'
    uncheck :doorkeeper_application_trusted
    uncheck :doorkeeper_application_confidential

    click_on 'Submit'
    expect(page).to have_content('test_changed')
    expect(page).to have_content('Application ID')
    expect(page).to have_content('Secret')
    expect(page).to have_content('Trusted N')
    expect(page).to have_content('Confidential N')

    visit admin_applications_path
    page.within '.oauth-applications' do
      click_on 'Destroy'
    end
    expect(page.find('.oauth-applications')).not_to have_content('test_changed')
  end

  context 'when scopes are blank' do
    it 'returns an error' do
      visit admin_applications_path

      click_on 'New application'
      expect(page).to have_content('New application')

      fill_in :doorkeeper_application_name, with: 'test'
      fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
      click_on 'Submit'

      expect(page).to have_content("Scopes can't be blank")
    end
  end
end
