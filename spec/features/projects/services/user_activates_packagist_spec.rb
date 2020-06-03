# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Packagist' do
  include_context 'project service activation'

  before do
    stub_request(:post, /.*packagist.org.*/)
  end

  it 'activates service', :js do
    visit_project_integration('Packagist')
    fill_in('Username', with: 'theUser')
    fill_in('Token', with: 'verySecret')

    click_test_then_save_integration

    expect(page).to have_content('Packagist activated.')
  end
end
