# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Chat' do
  let(:user) { create(:user) }
  let(:integration) { create(:service) }

  before do
    sign_in(user)
  end

  describe 'uses authorization link' do
    let(:params) do
      { team_id: 'T00', team_domain: 'my_chat_team', user_id: 'U01', user_name: 'my_chat_user' }
    end

    let!(:authorize_url) { ChatNames::AuthorizeUserService.new(integration, params).execute }
    let(:authorize_path) { URI.parse(authorize_url).request_uri }

    before do
      visit authorize_path
    end

    context 'clicks authorize' do
      before do
        click_button 'Authorize'
      end

      it 'goes to list of chat names and see chat account' do
        expect(page.current_path).to eq(profile_chat_names_path)
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
        expect(page.current_path).to eq(profile_chat_names_path)
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
    let!(:chat_name) { create(:chat_name, user: user, integration: integration) }

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
