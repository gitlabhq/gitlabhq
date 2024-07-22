# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Set up Mattermost slash commands', :js, feature_category: :integrations do
  describe 'user visits the mattermost slash command config page' do
    include_context 'project integration activation'

    before do
      stub_mattermost_setting(enabled: mattermost_enabled)
      visit_project_integration('Mattermost slash commands')
    end

    context 'mattermost integration is enabled' do
      let(:mattermost_enabled) { true }

      describe 'activation' do
        let(:edit_path) { edit_project_settings_integration_path(project, :mattermost_slash_commands) }

        include_examples 'user activates the Mattermost Slash Command integration'
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
        expect(page).to have_content('This is the only available team that you are a member of.')
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
        expect(page).to have_content('The list shows all available teams that you are a member of.')
      end

      it 'shows a select with team options user is a member of multiple teams' do
        stub_teams(count: 2)

        click_link 'Add to Mattermost'

        select_element = find('#mattermost_team_id')

        expect(select_element['disabled']).to eq('false')
        expect(select_element.all('option').count).to eq(3)
      end

      it 'shows an error alert with the error message if there is an error requesting teams' do
        allow_next_instance_of(Integrations::MattermostSlashCommands) do |integration|
          allow(integration).to receive(:list_teams).and_return([[], 'test mattermost error message'])
        end

        click_link 'Add to Mattermost'

        expect(page).to have_selector('.gl-alert')
        expect(page).to have_content('test mattermost error message')
      end

      def stub_teams(count: 0)
        teams = create_teams(count)

        allow_next_instance_of(Integrations::MattermostSlashCommands) do |integration|
          allow(integration).to receive(:list_teams).and_return([teams, nil])
        end

        teams
      end

      def create_teams(count = 0)
        teams = []

        count.times do |i|
          teams.push({ "id" => "x#{i}", "display_name" => "x#{i}-name" })
        end

        teams
      end
    end

    context 'mattermost integration is not enabled' do
      let(:mattermost_enabled) { false }

      it 'shows the correct trigger url' do
        value = find_field('request_url').value

        expect(value).to match("api/v4/projects/#{project.id}/integrations/mattermost_slash_commands/trigger")
      end

      it 'shows a token placeholder' do
        token_placeholder = find_field('service-token')['placeholder']

        expect(token_placeholder).to eq('')
      end
    end
  end

  describe 'stable logo url' do
    it 'shows a publicly available logo' do
      expect(File.exist?(Rails.root.join('public/slash-command-logo.png'))).to be_truthy
    end
  end
end
