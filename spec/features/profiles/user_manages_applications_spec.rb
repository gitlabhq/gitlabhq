# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages applications' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit applications_profile_path
  end

  it 'manages applications' do
    expect(page).to have_content 'Add new application'

    fill_in :doorkeeper_application_name,         with: 'test'
    fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
    check :doorkeeper_application_scopes_read_user
    click_on 'Save application'

    expect(page).to have_content 'Application: test'
    expect(page).to have_content 'Application ID'
    expect(page).to have_content 'Secret'
    expect(page).to have_content 'Confidential Yes'

    click_on 'Edit'

    expect(page).to have_content 'Edit application'
    fill_in :doorkeeper_application_name, with: 'test_changed'
    uncheck :doorkeeper_application_confidential
    click_on 'Save application'

    expect(page).to have_content 'test_changed'
    expect(page).to have_content 'Application ID'
    expect(page).to have_content 'Secret'
    expect(page).to have_content 'Confidential No'

    visit applications_profile_path

    page.within '.oauth-applications' do
      click_on 'Destroy'
    end
    expect(page.find('.oauth-applications')).not_to have_content 'test_changed'
  end

  context 'when scopes are blank' do
    it 'returns an error' do
      expect(page).to have_content 'Add new application'

      fill_in :doorkeeper_application_name,         with: 'test'
      fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
      click_on 'Save application'

      expect(page).to have_content("Scopes can't be blank")
    end
  end
end
