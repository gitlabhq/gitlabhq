require 'spec_helper'

feature 'Setup Mattermost slash commands', feature: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:service) { project.create_mattermost_slash_commands_service }
  let(:mattermost_enabled) { true }

  before do
    Settings.mattermost['enabled'] = mattermost_enabled
    project.team << [user, :master]
    login_as(user)
    visit edit_namespace_project_service_path(project.namespace, project, service)
  end

  describe 'user visits the mattermost slash command config page', js: true do
    it 'shows a help message' do
      wait_for_ajax

      expect(page).to have_content("This service allows GitLab users to perform common")
    end

    it 'shows the token after saving' do
      token = ('a'..'z').to_a.join

      fill_in 'service_token', with: token
      click_on 'Save'

      value = find_field('service_token').value

      expect(value).to eq(token)
    end

    describe 'mattermost service is enabled' do
      it 'shows the add to mattermost button' do
        expect(page).to have_link 'Add to Mattermost'
      end
    end

    describe 'mattermost service is not enabled' do
      let(:mattermost_enabled) { false }

      it 'shows the correct trigger url' do
        value = find_field('request_url').value

        expect(value).to match("api/v3/projects/#{project.id}/services/mattermost_slash_commands/trigger")
      end
    end
  end
end
