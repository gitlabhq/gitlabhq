require 'spec_helper'

feature 'Setup Mattermost slash commands', feature: true do
  include WaitForAjax

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:service) { project.create_mattermost_slash_commands_service }

  before do
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
      let(:info) { find('.services-installation-info') }

      before do
        Gitlab.config.mattermost.enabled = true
      end

      it 'shows the correct mattermost url' do
        expect(page).to have_content Gitlab.config.mattermost.host
      end

      describe 'mattermost service is active' do
        before do
          service.active = true
        end

        it 'shows that mattermost is active' do
          expect(info).to have_content 'Installed'
          expect(info).not_to have_content 'Not installed'
        end

        it 'shows the edit mattermost button' do
          expect(info).to have_button 'Edit Mattermost'
        end
      end

      describe 'mattermost service is not active' do
        before do
          service.active = false
        end

        it 'shows that mattermost is not active' do
          expect(info).to have_content 'Not installed'
        end

        it 'shows the add to mattermost button' do
          expect(info).to have_button 'Add to Mattermost'
        end
      end
    end

    describe 'mattermost service is not enabled' do
      before do
        Gitlab.config.mattermost.enabled = false
      end

      it 'shows the correct trigger url' do
        value = find_field('request_url').value

        expect(value).to match("api/v3/projects/#{project.id}/services/mattermost_slash_commands/trigger")
      end
    end
  end
end
