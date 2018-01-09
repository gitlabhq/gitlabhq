require 'spec_helper'

feature 'Slack slash commands' do
  given(:user) { create(:user) }
  given(:project) { create(:project) }
  given(:service) { project.create_slack_slash_commands_service }

  background do
    project.add_master(user)
    sign_in(user)
    visit edit_project_service_path(project, service)
  end

  it 'shows a token placeholder' do
    token_placeholder = find_field('service_token')['placeholder']

    expect(token_placeholder).to eq('XXxxXXxxXXxxXXxxXXxxXXxx')
  end

  it 'shows a help message' do
    expect(page).to have_content('This service allows users to perform common')
  end

  it 'redirects to the integrations page after saving but not activating' do
    fill_in 'service_token', with: 'token'
    click_on 'Save'

    expect(current_path).to eq(project_settings_integrations_path(project))
    expect(page).to have_content('Slack slash commands settings saved, but not activated.')
  end

  it 'redirects to the integrations page after activating' do
    fill_in 'service_token', with: 'token'
    check 'service_active'
    click_on 'Save'

    expect(current_path).to eq(project_settings_integrations_path(project))
    expect(page).to have_content('Slack slash commands activated.')
  end

  it 'shows the correct trigger url' do
    value = find_field('url').value
    expect(value).to match("api/v4/projects/#{project.id}/services/slack_slash_commands/trigger")
  end
end
