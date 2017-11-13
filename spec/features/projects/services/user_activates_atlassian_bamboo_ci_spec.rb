require 'spec_helper'

describe 'User activates Atlassian Bamboo CI' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('Atlassian Bamboo CI')
  end

  it 'activates service' do
    check('Active')
    fill_in('Bamboo url', with: 'http://bamboo.example.com')
    fill_in('Build key', with: 'KEY')
    fill_in('Username', with: 'user')
    fill_in('Password', with: 'verySecret')
    click_button('Save')

    expect(page).to have_content('Atlassian Bamboo CI activated.')

    # Password field should not be filled in.
    click_link('Atlassian Bamboo CI')

    expect(find_field('Enter new password').value).to be_nil
  end
end
