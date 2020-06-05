# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Atlassian Bamboo CI' do
  include_context 'project service activation'

  before do
    stub_request(:get, /.*bamboo.example.com.*/)
  end

  it 'activates service', :js do
    visit_project_integration('Atlassian Bamboo CI')
    fill_in('Bamboo url', with: 'http://bamboo.example.com')
    fill_in('Build key', with: 'KEY')
    fill_in('Username', with: 'user')
    fill_in('Password', with: 'verySecret')

    click_test_integration

    expect(page).to have_content('Atlassian Bamboo CI activated.')

    # Password field should not be filled in.
    click_link('Atlassian Bamboo CI')

    expect(find_field('Enter new Password').value).to be_blank
  end
end
