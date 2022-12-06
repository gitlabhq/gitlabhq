# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Atlassian Bamboo CI', feature_category: :integrations do
  include_context 'project integration activation'

  before do
    stub_request(:get, /.*bamboo.example.com.*/)
  end

  it 'activates integration', :js do
    visit_project_integration('Atlassian Bamboo')
    fill_in('Bamboo URL', with: 'http://bamboo.example.com')
    fill_in('Build key', with: 'KEY')
    fill_in('Username', with: 'user')
    fill_in('Password', with: 'verySecret')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('Atlassian Bamboo settings saved and active.')

    # Password field should not be filled in.
    click_link('Atlassian Bamboo')

    expect(find_field('Enter new password').value).to be_blank
    expect(page).to have_content('Leave blank to use your current password')
  end
end
