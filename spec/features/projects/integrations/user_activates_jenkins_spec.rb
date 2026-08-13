# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Jenkins', :js, feature_category: :continuous_integration do
  include_context 'project integration activation'

  before do
    visit_project_integration('Jenkins')
    check('Push')
    check('Merge request')
    fill_in('Jenkins server URL', with: 'http://jenkins.example.com')
    fill_in('Project name', with: 'my_project')
    fill_in('Username', with: 'user')
    fill_in('Password', with: 'verySecret')
  end

  context 'when the connection test succeeds' do
    before do
      stub_request(:post, %r{jenkins\.example\.com}).to_return(status: 200)
    end

    it 'activates the integration' do
      click_test_then_save_integration(expect_test_to_fail: false)

      expect(page).to have_content('Jenkins settings saved and active.')
    end
  end

  context 'when the connection test fails' do
    before do
      stub_request(:post, %r{jenkins\.example\.com}).to_return(status: 500)
    end

    it 'reports the failed connection and still saves the integration' do
      click_test_then_save_integration(expect_test_to_fail: true)

      expect(page).to have_content('Jenkins settings saved and active.')
    end
  end
end
