require 'spec_helper'

describe 'User views services' do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)

    visit(project_settings_integrations_path(project))
  end

  it 'shows the list of available services' do
    expect(page).to have_content('Project services')
    expect(page).to have_content('Campfire')
    expect(page).to have_content('HipChat')
    expect(page).to have_content('Assembla')
    expect(page).to have_content('Pushover')
    expect(page).to have_content('Atlassian Bamboo')
    expect(page).to have_content('JetBrains TeamCity')
    expect(page).to have_content('Asana')
    expect(page).to have_content('Irker (IRC gateway)')
    expect(page).to have_content('Packagist')
  end
end
