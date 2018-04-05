require 'spec_helper'

describe 'User activates Prometheus' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Prometheus')
  end

  it 'activates service' do
    check('Active')
    fill_in('API URL', with: 'http://prometheus.example.com')
    click_button('Save changes')

    expect(page).to have_content('Prometheus activated.')
  end
end
