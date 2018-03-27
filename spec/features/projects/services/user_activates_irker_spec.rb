require 'spec_helper'

describe 'User activates Irker (IRC gateway)' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Irker (IRC gateway)')
  end

  it 'activates service' do
    check('Active')
    check('Colorize messages')
    fill_in('Recipients', with: 'irc://chat.freenode.net/#commits')
    click_button('Save')

    expect(page).to have_content('Irker (IRC gateway) activated.')
  end
end
