require 'spec_helper'

feature 'Slack slash commands', feature: true do
  given(:user) { create(:user) }
  given(:project) { create(:project) }
  given(:service) { project.create_slack_slash_commands_service }

  background do
    project.team << [user, :master]
    login_as(user)
    visit edit_namespace_project_service_path(project.namespace, project, service)
  end

  it 'shows a token placeholder' do
    token_placeholder = find_field('service_token')['placeholder']

    expect(token_placeholder).to eq('XXxxXXxxXXxxXXxxXXxxXXxx')
  end

  it 'shows a help message' do
    expect(page).to have_content('This service allows users to perform common')
  end

  it 'shows the token after saving' do
    fill_in 'service_token', with: 'token'
    click_on 'Save'

    value = find_field('service_token').value

    expect(value).to eq('token')
  end

  it 'shows the correct trigger url' do
    value = find_field('url').value
    expect(value).to match("api/v3/projects/#{project.id}/services/slack_slash_commands/trigger")
  end
end
