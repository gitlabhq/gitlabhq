require 'spec_helper'

feature 'Slack slash commands', feature: true do
  include WaitForAjax

  given(:user) { create(:user) }
  given(:project) { create(:project) }
  given(:service) { project.create_slack_slash_commands_service }

  background do
    project.team << [user, :master]
    login_as(user)
  end

  scenario 'user visits the slack slash command config page and shows a help message', js: true do
    visit edit_namespace_project_service_path(project.namespace, project, service)

    wait_for_ajax

    expect(page).to have_content('This service allows GitLab users to perform common')
  end

  scenario 'shows the token after saving' do
    visit edit_namespace_project_service_path(project.namespace, project, service)

    fill_in 'service_token', with: 'token'
    click_on 'Save'

    value = find_field('service_token').value

    expect(value).to eq('token')
  end

  scenario 'shows the correct trigger url' do
    visit edit_namespace_project_service_path(project.namespace, project, service)

    value = find_field('url').value
    expect(value).to match("api/v3/projects/#{project.id}/services/slack_slash_commands/trigger")
  end
end
