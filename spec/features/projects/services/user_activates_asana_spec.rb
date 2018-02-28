require 'spec_helper'

describe 'User activates Asana' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Asana')
  end

  it 'activates service' do
    check('Active')
    fill_in('Api key', with: 'verySecret')
    fill_in('Restrict to branch', with: 'verySecret')
    click_button('Save')

    expect(page).to have_content('Asana activated.')
  end
end
