require 'spec_helper'

describe 'User activates Packagist' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Packagist')
  end

  it 'activates service' do
    check('Active')
    fill_in('Username', with: 'theUser')
    fill_in('Token', with: 'verySecret')
    click_button('Save')

    expect(page).to have_content('Packagist activated.')
  end
end
