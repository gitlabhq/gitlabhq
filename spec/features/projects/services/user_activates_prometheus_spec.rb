# frozen_string_literal: true

require 'spec_helper'

describe 'User activates Prometheus' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Prometheus')
  end

  it 'does not activate service and informs about deprecation' do
    check('Active')
    fill_in('API URL', with: 'http://prometheus.example.com')
    click_button('Save changes')

    expect(page).not_to have_content('Prometheus activated.')
    expect(page).to have_content('Fields on this page has been deprecated.')
  end
end
