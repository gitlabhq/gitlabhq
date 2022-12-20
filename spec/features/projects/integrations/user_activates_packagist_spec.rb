# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Packagist', feature_category: :integrations do
  include_context 'project integration activation'

  before do
    stub_request(:post, /.*packagist.org.*/)
  end

  it 'activates integration', :js do
    visit_project_integration('Packagist')
    fill_in('Username', with: 'theUser')
    fill_in('Token', with: 'verySecret')

    click_test_then_save_integration

    expect(page).to have_content('Packagist settings saved and active.')
  end
end
