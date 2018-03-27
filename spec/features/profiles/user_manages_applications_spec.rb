require 'spec_helper'

describe 'User manages applications' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit applications_profile_path
  end

  it 'manages applications' do
    expect(page).to have_content 'Add new application'

    fill_in :doorkeeper_application_name,         with: 'test'
    fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
    click_on 'Save application'

    expect(page).to have_content 'Application: test'
    expect(page).to have_content 'Application Id'
    expect(page).to have_content 'Secret'

    click_on 'Edit'

    expect(page).to have_content 'Edit application'
    fill_in :doorkeeper_application_name, with: 'test_changed'
    click_on 'Save application'

    expect(page).to have_content 'test_changed'
    expect(page).to have_content 'Application Id'
    expect(page).to have_content 'Secret'

    visit applications_profile_path

    page.within '.oauth-applications' do
      click_on 'Destroy'
    end
    expect(page.find('.oauth-applications')).not_to have_content 'test_changed'
  end
end
