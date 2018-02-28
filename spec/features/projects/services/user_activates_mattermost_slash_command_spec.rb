require 'spec_helper'

feature 'Setup Mattermost slash commands', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:service) { project.create_mattermost_slash_commands_service }
  let(:mattermost_enabled) { true }

  before do
    stub_mattermost_setting(enabled: mattermost_enabled)
    project.add_master(user)
    sign_in(user)
    visit edit_project_service_path(project, service)
  end

  describe 'user visits the mattermost slash command config page' do
    it 'shows a help message' do
      expect(page).to have_content("This service allows users to perform common")
    end

    it 'shows a token placeholder' do
      token_placeholder = find_field('service_token')['placeholder']

      expect(token_placeholder).to eq('XXxxXXxxXXxxXXxxXXxxXXxx')
    end

    it 'redirects to the integrations page after saving but not activating' do
      token = ('a'..'z').to_a.join

      fill_in 'service_token', with: token
      click_on 'Save changes'

      expect(current_path).to eq(project_settings_integrations_path(project))
      expect(page).to have_content('Mattermost slash commands settings saved, but not activated.')
    end

    it 'redirects to the integrations page after activating' do
      token = ('a'..'z').to_a.join

      fill_in 'service_token', with: token
      check 'service_active'
      click_on 'Save changes'

      expect(current_path).to eq(project_settings_integrations_path(project))
      expect(page).to have_content('Mattermost slash commands activated.')
    end

    it 'shows the add to mattermost button' do
      expect(page).to have_link('Add to Mattermost')
    end

    it 'shows an explanation if user is a member of no teams' do
      stub_teams(count: 0)

      click_link 'Add to Mattermost'

      expect(page).to have_content('You aren’t a member of any team on the Mattermost instance')
      expect(page).to have_link('join a team', href: "#{Gitlab.config.mattermost.host}/select_team")
    end

    it 'shows an explanation if user is a member of 1 team' do
      stub_teams(count: 1)

      click_link 'Add to Mattermost'

      expect(page).to have_content('The team where the slash commands will be used in')
      expect(page).to have_content('This is the only available team.')
    end

    it 'shows a disabled prefilled select if user is a member of 1 team' do
      teams = stub_teams(count: 1)

      click_link 'Add to Mattermost'

      team_name = teams.first['display_name']
      select_element = find('#mattermost_team_id')
      selected_option = select_element.find('option[selected]')

      expect(select_element['disabled']).to eq("true")
      expect(selected_option).to have_content(team_name.to_s)
    end

    it 'has a hidden input for the prefilled value if user is a member of 1 team' do
      teams = stub_teams(count: 1)

      click_link 'Add to Mattermost'

      expect(find('input#mattermost_team_id', visible: false).value).to eq(teams.first['id'])
    end

    it 'shows an explanation user is a member of multiple teams' do
      stub_teams(count: 2)

      click_link 'Add to Mattermost'

      expect(page).to have_content('Select the team where the slash commands will be used in')
      expect(page).to have_content('The list shows all available teams.')
    end

    it 'shows a select with team options user is a member of multiple teams' do
      stub_teams(count: 2)

      click_link 'Add to Mattermost'

      select_element = find('#mattermost_team_id')

      expect(select_element['disabled']).to be_falsey
      expect(select_element.all('option').count).to eq(3)
    end

    it 'shows an error alert with the error message if there is an error requesting teams' do
      allow_any_instance_of(MattermostSlashCommandsService).to receive(:list_teams) { [[], 'test mattermost error message'] }

      click_link 'Add to Mattermost'

      expect(page).to have_selector('.alert')
      expect(page).to have_content('test mattermost error message')
    end

    it 'enables the submit button if the required fields are provided', :js do
      stub_teams(count: 1)

      click_link 'Add to Mattermost'

      expect(find('input[type="submit"]')['disabled']).not_to eq("true")
    end

    it 'disables the submit button if the required fields are not provided', :js do
      stub_teams(count: 1)

      click_link 'Add to Mattermost'

      fill_in('mattermost_trigger', with: '')

      expect(find('input[type="submit"]')['disabled']).to eq("true")
    end

    def stub_teams(count: 0)
      teams = create_teams(count)

      allow_any_instance_of(MattermostSlashCommandsService).to receive(:list_teams) { [teams, nil] }

      teams
    end

    def create_teams(count = 0)
      teams = []

      count.times do |i|
        teams.push({ "id" => "x#{i}", "display_name" => "x#{i}-name" })
      end

      teams
    end

    describe 'mattermost service is not enabled' do
      let(:mattermost_enabled) { false }

      it 'shows the correct trigger url' do
        value = find_field('request_url').value

        expect(value).to match("api/v4/projects/#{project.id}/services/mattermost_slash_commands/trigger")
      end

      it 'shows a token placeholder' do
        token_placeholder = find_field('service_token')['placeholder']

        expect(token_placeholder).to eq('XXxxXXxxXXxxXXxxXXxxXXxx')
      end
    end
  end

  describe 'stable logo url' do
    it 'shows a publicly available logo' do
      expect(File.exist?(Rails.root.join('public/slash-command-logo.png')))
    end
  end
end
