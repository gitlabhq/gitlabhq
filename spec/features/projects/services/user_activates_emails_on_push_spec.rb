# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User activates Emails on push' do
  include_context 'project service activation'

  it 'activates service', :js do
    visit_project_integration('Emails on push')
    fill_in('Recipients', with: 'qa@company.name')

    click_test_integration

    expect(page).to have_content('Emails on push activated.')
  end
end
