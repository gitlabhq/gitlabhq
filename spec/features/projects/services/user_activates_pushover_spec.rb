require 'spec_helper'

describe 'User activates Pushover' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Pushover')
  end

  it 'activates service' do
    check('Active')
    fill_in('Api key', with: 'verySecret')
    fill_in('User key', with: 'verySecret')
    fill_in('Device', with: 'myDevice')
    select('High Priority', from: 'Priority')
    select('Bike', from: 'Sound')
    click_button('Save')

    expect(page).to have_content('Pushover activated.')
  end
end
