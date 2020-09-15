# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Flowdock' do
  include_context 'project service activation' do
    let(:project) { create(:project, :repository) }
  end

  before do
    stub_request(:post, /.*api.flowdock.com.*/)
  end

  it 'activates service', :js do
    visit_project_integration('Flowdock')
    fill_in('Token', with: 'verySecret')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('Flowdock settings saved and active.')
  end
end
