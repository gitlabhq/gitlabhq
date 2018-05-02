require 'rails_helper'

feature 'Profile > Active Sessions', :clean_gitlab_redis_shared_state do
  let(:user) do
    create(:user).tap do |user|
      user.current_sign_in_at = Time.current
    end
  end

  around do |example|
    Timecop.freeze(Time.zone.parse('2018-03-12 09:06')) do
      example.run
    end
  end

  scenario 'User sees their active sessions' do
    Capybara::Session.new(:session1)
    Capybara::Session.new(:session2)

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

    using_session :session1 do
      visit profile_active_sessions_path

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
    end
  end

  scenario 'User can revoke a session', :js, :redis_session_store do
    Capybara::Session.new(:session1)
    Capybara::Session.new(:session2)

    # set an additional session in another browser
    using_session :session2 do
      gitlab_sign_in(user)
    end

    using_session :session1 do
      gitlab_sign_in(user)
      visit profile_active_sessions_path

      expect(page).to have_link('Revoke', count: 1)

      accept_confirm { click_on 'Revoke' }

      expect(page).not_to have_link('Revoke')
    end

    using_session :session2 do
      visit profile_active_sessions_path

      expect(page).to have_content('You need to sign in or sign up before continuing.')
    end
  end
end
