# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Chat', feature_category: :integrations do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'uses authorization link' do
    let(:params) do
      {
        team_id: 'f1924a8db44ff3bb41c96424cdc20676',
        team_domain: 'my_chat_team',
        user_id: 'ay5sq51sebfh58ktrce5ijtcwy',
        user_name: 'my_chat_user'
      }
    end

    let!(:authorize_url) { ChatNames::AuthorizeUserService.new(params).execute }
    let(:authorize_path) { URI.parse(authorize_url).request_uri }

    before do
      visit authorize_path
    end

    it 'names the Mattermost integration correctly' do
      expect(page).to have_content(
        'An application called Mattermost slash commands is requesting access to your GitLab account'
      )
      expect(page).to have_content('Authorize Mattermost slash commands')
    end

    context 'when params are of the GitLab for Slack app' do
      let(:params) do
        { team_id: 'T00', team_domain: 'my_chat_team', user_id: 'U01', user_name: 'my_chat_user' }
      end

      shared_examples 'names the GitLab for Slack app integration correctly' do
        specify do
          expect(page).to have_content(
            'An application called GitLab for Slack app is requesting access to your GitLab account'
          )
          expect(page).to have_content('Authorize GitLab for Slack app')
        end
      end

      include_examples 'names the GitLab for Slack app integration correctly'

      context 'with a Slack enterprise-enabled team' do
        let(:params) { super().merge(user_id: 'W01') }

        include_examples 'names the GitLab for Slack app integration correctly'
      end
    end

    context 'clicks authorize' do
      before do
        click_button 'Authorize'
      end

      it 'goes to list of chat names and see chat account' do
        expect(page).to have_current_path(profile_chat_names_path, ignore_query: true)
        expect(page).to have_content('my_chat_team')
        expect(page).to have_content('my_chat_user')
      end

      it 'second use of link is denied' do
        visit authorize_path

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end

    context 'clicks deny' do
      before do
        click_button 'Deny'
      end

      it 'goes to list of chat names and do not see chat account' do
        expect(page).to have_current_path(profile_chat_names_path, ignore_query: true)
        expect(page).not_to have_content('my_chat_team')
        expect(page).not_to have_content('my_chat_user')
      end

      it 'second use of link is denied' do
        visit authorize_path

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'visits chat accounts' do
    let_it_be(:chat_name) { create(:chat_name, user: user) }

    before do
      visit profile_chat_names_path
    end

    it 'sees chat user' do
      expect(page).to have_content(chat_name.team_domain)
      expect(page).to have_content(chat_name.chat_name)
    end

    it 'removes chat account' do
      click_link 'Remove'

      expect(page).to have_content("You don't have any active chat names.")
    end
  end
end
