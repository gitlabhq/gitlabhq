# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Assembla' do
  include_context 'project service activation'

  before do
    stub_request(:post, /.*atlas.assembla.com.*/)
  end

  it 'activates service', :js do
    visit_project_integration('Assembla')
    fill_in('Token', with: 'verySecret')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('Assembla settings saved and active.')
  end
end
