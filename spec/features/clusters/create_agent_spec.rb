# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cluster agent registration', :js, feature_category: :deployment_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, maintainer_of: project) }
  let_it_be(:token) { Devise.friendly_token }

  before do
    allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
    allow(Gitlab::Kas).to receive(:internal_url).and_return('kas.example.internal')

    allow(Devise).to receive(:friendly_token).and_return(token)

    sign_in(current_user)
    visit project_clusters_path(project)
  end

  describe 'when GRPC is available' do
    before do
      allow_next_instance_of(Gitlab::Kas::Client) do |client|
        allow(client).to receive(:get_connected_agents_by_agent_ids).and_return([])
      end
    end

    it 'allows the user to select an agent to install, and displays the resulting agent token' do
      find_by_testid('clusters-default-action-button').click

      expect(page).to have_content('Create and register')

      find_by_testid('agent-name-input').set('example-agent-2')
      click_button('Create and register')

      expect(page).to have_content('You cannot see this token again after you close this window.')
      expect(page).to have_content(token)
      expect(page).to have_content('helm upgrade --install')
      expect(page).to have_content('example-agent-2')

      within find('.modal-footer') do
        click_button('Close')
      end

      expect(page).to have_link('example-agent-2')
    end

    it 'fails to create an agent with invalid name' do
      find_by_testid('clusters-default-action-button').click

      expect(page).to have_content('Create and register')

      find_by_testid('agent-name-input').set('-invalid@')
      click_button('Create and register')

      expect(page).to have_content('Failed to register an agent')
      expect(page).to have_content(
        'Name can contain only lowercase letters, digits, and \'-\', ' \
          'but cannot start or end with \'-\''
      )

      within find('.modal-footer') do
        click_button('Cancel')
      end

      expect(page).not_to have_link('-invalid@')
    end
  end

  describe 'when GRPC is not available' do
    it 'shows an error in the agent registration modal' do
      find_by_testid('clusters-default-action-button').click

      expect(page).to have_content('Create and register')

      find_by_testid('agent-name-input').set('example-agent-2')
      click_button('Create and register')

      expect(page).to have_content('Failed to register an agent')
      expect(page).to have_content('GRPC::Unavailable')
    end
  end
end
