require 'spec_helper'

feature 'Setup Mattermost slash commands', feature: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:service) { project.create_mattermost_slash_commands_service }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  describe 'user visites the mattermost slash command config page', js: true do
    it 'shows a help message' do
      visit edit_namespace_project_service_path(project.namespace, project, service)

      wait_for_ajax

      expect(page).to have_content("This service allows GitLab users to perform common")
    end
  end

  describe 'saving a token' do
    let(:token) { ('a'..'z').to_a.join }

    it 'shows the token after saving' do
      visit edit_namespace_project_service_path(project.namespace, project, service)

      fill_in 'service_token', with: token
      click_on 'Save'

      value = find_field('service_token').value

      expect(value).to eq(token)
    end
  end

  describe 'the trigger url' do
    it 'shows the correct url' do
      visit edit_namespace_project_service_path(project.namespace, project, service)

      value = find_field('request_url').value
      expect(value).to match("api/v3/projects/#{project.id}/services/mattermost_slash_commands/trigger")
    end
  end
end
