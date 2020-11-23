# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin activates Prometheus', :js do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)

    visit(admin_application_settings_services_path)

    click_link('Prometheus')
  end

  it 'activates service' do
    check('Active')
    fill_in('API URL', with: 'http://prometheus.example.com')
    click_button('Save changes')

    expect(page).to have_content('Application settings saved successfully')
  end
end
