require 'spec_helper'

feature 'Chat slash commands', models: true do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:service) do
    class ExampleChatSlashCommandsService < ChatSlashCommandsService
      def self.to_param
        'mattermost_slash_commands'
      end
    end

    ExampleChatSlashCommandsService.new
  end

  before do
    project.team << [user, :master]
    login_as(user)
    visit edit_namespace_project_service_path(project.namespace, project, service)
  end

  it 'shows a token placeholder' do
    token_placeholder = find_field('service_token')['placeholder']

    expect(token_placeholder).to eq('XXxxXXxxXXxxXXxxXXxxXXxx')
  end

  it 'prevents autocomplete for token field' do
    autocomplete = find_field('service_token')['autocomplete']

    expect(autocomplete).to eq('off')
  end
end
