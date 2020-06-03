# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Access Tokens', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:bot_user) { create(:user, :project_bot) }
  let_it_be(:project) { create(:project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  def create_project_access_token
    project.add_maintainer(bot_user)

    create(:personal_access_token, user: bot_user)
  end

  def active_project_access_tokens
    find('.table.active-tokens')
  end

  def no_project_access_tokens_message
    find('.settings-message')
  end

  def created_project_access_token
    find('#created-personal-access-token').value
  end

  describe 'token creation' do
    it 'allows creation of a project access token' do
      name = 'My project access token'

      visit project_settings_access_tokens_path(project)
      fill_in 'Name', with: name

      # Set date to 1st of next month
      find_field('Expires at').click
      find('.pika-next').click
      click_on '1'

      # Scopes
      check 'api'
      check 'read_api'

      click_on 'Create project access token'

      expect(active_project_access_tokens).to have_text(name)
      expect(active_project_access_tokens).to have_text('In')
      expect(active_project_access_tokens).to have_text('api')
      expect(active_project_access_tokens).to have_text('read_api')
      expect(created_project_access_token).not_to be_empty
    end
  end

  describe 'active tokens' do
    let!(:project_access_token) { create_project_access_token }

    it 'shows active project access tokens' do
      visit project_settings_access_tokens_path(project)

      expect(active_project_access_tokens).to have_text(project_access_token.name)
    end
  end

  describe 'inactive tokens' do
    let!(:project_access_token) { create_project_access_token }

    no_active_tokens_text = 'This project has no active access tokens.'

    it 'allows revocation of an active token' do
      visit project_settings_access_tokens_path(project)
      accept_confirm { click_on 'Revoke' }

      expect(page).to have_selector('.settings-message')
      expect(no_project_access_tokens_message).to have_text(no_active_tokens_text)
    end

    it 'removes expired tokens from active section' do
      project_access_token.update(expires_at: 5.days.ago)
      visit project_settings_access_tokens_path(project)

      expect(page).to have_selector('.settings-message')
      expect(no_project_access_tokens_message).to have_text(no_active_tokens_text)
    end
  end
end
