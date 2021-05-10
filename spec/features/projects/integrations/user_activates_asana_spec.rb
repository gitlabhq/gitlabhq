# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Asana' do
  include_context 'project service activation'

  it 'activates service', :js do
    visit_project_integration('Asana')
    fill_in('API key', with: 'verySecret')
    fill_in('Restrict to branch', with: 'verySecret')

    click_test_then_save_integration

    expect(page).to have_content('Asana settings saved and active.')
  end
end
