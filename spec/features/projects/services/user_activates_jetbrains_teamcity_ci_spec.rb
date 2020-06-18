# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates JetBrains TeamCity CI' do
  include_context 'project service activation'

  before do
    stub_request(:post, /.*teamcity.example.com.*/)
  end

  it 'activates service', :js do
    visit_project_integration('JetBrains TeamCity CI')
    check('Push')
    check('Merge Request')
    fill_in('Teamcity url', with: 'http://teamcity.example.com')
    fill_in('Build type', with: 'GitlabTest_Build')
    fill_in('Username', with: 'user')
    fill_in('Password', with: 'verySecret')

    click_test_integration

    expect(page).to have_content('JetBrains TeamCity CI activated.')
  end
end
