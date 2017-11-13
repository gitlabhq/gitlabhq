require 'rails_helper'

feature 'Profile > Chat' do
  given(:user) { create(:user) }
  given(:service) { create(:service) }

  before do
    sign_in(user)
  end

  describe 'uses authorization link' do
    given(:params) do
      { team_id: 'T00', team_domain: 'my_chat_team', user_id: 'U01', user_name: 'my_chat_user' }
    end
    given!(:authorize_url) { ChatNames::AuthorizeUserService.new(service, params).execute }
    given(:authorize_path) { URI.parse(authorize_url).request_uri }

    before do
      visit authorize_path
    end

    context 'clicks authorize' do
      before do
        click_button 'Authorize'
      end

      scenario 'goes to list of chat names and see chat account' do
        expect(page.current_path).to eq(profile_chat_names_path)
        expect(page).to have_content('my_chat_team')
        expect(page).to have_content('my_chat_user')
      end

      scenario 'second use of link is denied' do
        visit authorize_path

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end

    context 'clicks deny' do
      before do
        click_button 'Deny'
      end

      scenario 'goes to list of chat names and do not see chat account' do
        expect(page.current_path).to eq(profile_chat_names_path)
        expect(page).not_to have_content('my_chat_team')
        expect(page).not_to have_content('my_chat_user')
      end

      scenario 'second use of link is denied' do
        visit authorize_path

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'visits chat accounts' do
    given!(:chat_name) { create(:chat_name, user: user, service: service) }

    before do
      visit profile_chat_names_path
    end

    scenario 'sees chat user' do
      expect(page).to have_content(chat_name.team_domain)
      expect(page).to have_content(chat_name.chat_name)
    end

    scenario 'removes chat account' do
      click_link 'Remove'

      expect(page).to have_content("You don't have any active chat names.")
    end
  end
end
