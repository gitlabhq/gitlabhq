# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Emails on push', feature_category: :integrations do
  include_context 'project integration activation'

  it 'activates integration', :js do
    visit_project_integration('Emails on push')
    fill_in('Recipients', with: 'qa@company.name')

    click_test_then_save_integration(expect_test_to_fail: false)

    expect(page).to have_content('Emails on push settings saved and active.')
  end
end
