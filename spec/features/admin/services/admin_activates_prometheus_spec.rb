require 'spec_helper'

describe 'Admin activates Prometheus' do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in(admin)

    visit(admin_application_settings_services_path)

    click_link('Prometheus')
  end

  it 'activates service' do
    check('Active')
    fill_in('API URL', with: 'http://prometheus.example.com')
    click_button('Save')

    expect(page).to have_content('Application settings saved successfully')
  end
end
