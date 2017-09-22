require 'spec_helper'

describe 'User activates JetBrains TeamCity CI' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link('JetBrains TeamCity CI')
  end

  it 'activates service' do
    check('Active')
    fill_in('Teamcity url', with: 'http://teamcity.example.com')
    fill_in('Build type', with: 'GitlabTest_Build')
    fill_in('Username', with: 'user')
    fill_in('Password', with: 'verySecret')
    click_button('Save')

    expect(page).to have_content('JetBrains TeamCity CI activated.')
  end
end
