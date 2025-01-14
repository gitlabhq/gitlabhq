# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Active Sessions', :clean_gitlab_redis_shared_state, feature_category: :user_profile do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) do
    create(:user).tap do |user|
      user.current_sign_in_at = Time.current
    end
  end

  let(:admin) { create(:admin) }

  it 'user sees their active sessions' do
    travel_to(Time.zone.parse('2018-03-12 09:06')) do
      # note: headers can only be set on the non-js (aka. rack-test) driver
      using_session :session1 do
        Capybara.page.driver.header(
          'User-Agent',
          'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0'
        )

        gitlab_sign_in(user)
      end

      # set an additional session on another device
      using_session :session2 do
        Capybara.page.driver.header(
          'User-Agent',
          'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_3 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Mobile/12B466 [FBDV/iPhone7,2]'
        )

        gitlab_sign_in(user)
      end

      # set an admin session impersonating the user
      using_session :session3 do
        Capybara.page.driver.header(
          'User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36'
        )

        gitlab_sign_in(admin)
        enable_admin_mode!(admin)

        visit admin_user_path(user)

        click_link 'Impersonate'
      end

      using_session :session1 do
        visit user_settings_active_sessions_path

        expect(page).to(have_selector('ul.list-group li.list-group-item', text: 'Signed in on', count: 2))

        expect(page).to have_content(
          '127.0.0.1 ' \
          'This is your current session ' \
          'Firefox on Ubuntu ' \
          'Signed in on 12 Mar 09:06'
        )

        expect(page).to have_selector '[title="Desktop"]', count: 1

        expect(page).to have_content(
          '127.0.0.1 ' \
          'Last accessed on 12 Mar 09:06 ' \
          'Mobile Safari on iOS ' \
          'Signed in on 12 Mar 09:06'
        )

        expect(page).to have_selector '[title="Smartphone"]', count: 1

        expect(page).not_to have_content('Chrome on Windows')
      end
    end
  end

  it 'admin sees if the session is with admin mode', :enable_admin_mode do
    using_session :admin_session do
      gitlab_sign_in(admin)
      visit user_settings_active_sessions_path
      expect(page).to have_content('with Admin Mode')
    end
  end

  it 'does not display admin mode text in case its not' do
    using_session :admin_session do
      gitlab_sign_in(admin)
      visit user_settings_active_sessions_path
      expect(page).not_to have_content('with Admin Mode')
    end
  end

  it 'user can revoke a session', :js do
    # set an additional session in another browser
    using_session :session2 do
      gitlab_sign_in(user)
    end

    using_session :session1 do
      gitlab_sign_in(user)
      visit user_settings_active_sessions_path

      expect(page).to have_link('Revoke', count: 1)

      accept_gl_confirm(button_text: 'Revoke') do
        click_on 'Revoke'
      end

      expect(page).not_to have_link('Revoke')
    end

    using_session :session2 do
      visit user_settings_active_sessions_path

      expect(page).to have_content('You need to sign in or sign up before continuing.')
    end
  end
end
