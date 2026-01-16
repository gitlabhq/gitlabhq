# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Active sessions', :clean_gitlab_redis_shared_state, feature_category: :user_profile do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) do
    create(:user).tap do |user|
      user.current_sign_in_at = Time.current
    end
  end

  let(:admin) { create(:admin) }

  with_and_without_sign_in_form_vue do
    it 'user sees their active sessions' do
      travel_to(Time.zone.parse('2018-03-12 09:06')) do
        firefox_session_id = Rack::Session::SessionId.new('6919a6f1bb119dd7396fadc38fd18d0d')
        firefox_session = instance_double(ActionDispatch::Request::Session, id: firefox_session_id, '[]': {}, dig: {})
        firefox_request = instance_double(ActionDispatch::Request,
          user_agent: 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:58.0) Gecko/20100101 Firefox/58.0',
          remote_ip: '127.0.0.1',
          session: firefox_session
        )

        iphone_session_id = Rack::Session::SessionId.new('59822c7d9fcdfa03725eff41782ad97d')
        iphone_session = instance_double(ActionDispatch::Request::Session, id: iphone_session_id, '[]': {}, dig: {})
        iphone_request = instance_double(ActionDispatch::Request,
          user_agent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_1_3 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Mobile/12B466 [FBDV/iPhone7,2]',
          remote_ip: '127.0.0.1',
          session: iphone_session
        )

        ActiveSession.set(user, firefox_request)
        ActiveSession.set(user, iphone_request)

        # Admin session impersonating user. Shouldn't show up for the user.
        admin_session_id = Rack::Session::SessionId.new('5c8611e4f9c69645ad1a1492f4131358')
        admin_session = instance_double(ActionDispatch::Request::Session, id: admin_session_id, '[]': {}, dig: {})
        allow(admin_session).to receive(:[]).with(:impersonator_id).and_return(admin.id)
        admin_request = instance_double(ActionDispatch::Request,
          user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36',
          remote_ip: '127.0.0.1',
          session: admin_session
        )
        ActiveSession.set(user, admin_request)

        unless javascript_test? # rubocop:disable RSpec/AvoidConditionalStatements -- temporary until sign_in_form_vue feature flag is removed
          Capybara.page.driver.header(
            'User-Agent',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/120.0.0.0 Safari/537.36'
          )
        end

        gitlab_sign_in(user)

        visit user_settings_active_sessions_path

        expect(page).to(have_selector('ul.list-group li.list-group-item', text: 'Signed in on', count: 3))

        expect(page).to have_content(
          '127.0.0.1 ' \
          'This is your current session'
        )

        expect(page).to have_content(
          '127.0.0.1 ' \
          'Last accessed on 12 Mar 09:06 ' \
          'Firefox on Ubuntu ' \
          'Signed in on 12 Mar 09:06'
        )

        expect(page).to have_selector '[title="Desktop"]', count: 2

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

  with_and_without_sign_in_form_vue do
    it 'admin sees if the session is with admin mode', :enable_admin_mode do
      using_session :admin_session do
        gitlab_sign_in(admin)
        visit user_settings_active_sessions_path
        expect(page).to have_content('with Admin Mode')
        expect(page).not_to have_content('with Step-up Authentication')
      end
    end

    context 'when session step-up authenticated', :with_current_organization do
      let(:admin) { create(:omniauth_user, :admin, password_automatically_set: false, extern_uid: extern_uid, provider: provider_oidc) }
      let(:extern_uid) { 'my-uid' }
      let(:provider_oidc) { 'openid_connect' }

      let(:provider_oidc_config_with_step_up_auth) do
        GitlabSettings::Options.new(
          name: provider_oidc,
          step_up_auth: {
            admin_mode: {
              id_token: {
                required: { acr: 'gold' }
              }
            }
          }
        )
      end

      let(:additional_info) { { extra: { raw_info: { acr: 'gold' } } } }

      around do |example|
        with_omniauth_full_host { example.run }
      end

      before do
        user

        stub_omniauth_setting(enabled: true, auto_link_user: true, providers: [provider_oidc_config_with_step_up_auth])
      end

      it 'marks admin session as step-up authenticated' do
        using_session :admin_session do
          gitlab_sign_in(admin)

          gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid, additional_info: additional_info)

          visit user_settings_active_sessions_path

          within('.settings-section') do
            expect(page).to have_content('with Admin Mode')
            expect(page).to have_content('with Step-up Authentication')
          end
        end
      end

      it 'does not marks admin session as step-up authenticated when acr is not matching' do
        using_session :admin_session do
          gitlab_sign_in(admin)

          gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid, additional_info: { extra: { raw_info: { acr: 'bronze' } } })

          visit user_settings_active_sessions_path

          within('.settings-section') do
            expect(page).not_to have_content('with Admin Mode')
            expect(page).not_to have_content('with Step-up Authentication')
          end
        end
      end

      it 'does not marks admin session as step-up authenticated after leaving admin mode', :js do
        using_session :admin_session do
          gitlab_sign_in(admin)

          wait_for_requests

          gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid, additional_info: additional_info)

          wait_for_requests

          visit user_settings_active_sessions_path

          wait_for_requests

          within('.settings-section') do
            expect(page).to have_content('with Admin Mode')
            expect(page).to have_content('with Step-up Authentication')
          end

          gitlab_disable_admin_mode

          visit user_settings_active_sessions_path

          within('.settings-section') do
            expect(page).not_to have_content('with Admin Mode')
            expect(page).not_to have_content('with Step-up Authentication')
          end
        end
      end

      context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
        before do
          stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
        end

        it 'does not mark admin session as step-up authenticated' do
          using_session :admin_session do
            gitlab_sign_in(admin)

            gitlab_enable_admin_mode_sign_in_via(provider_oidc, admin, extern_uid, additional_info: additional_info)

            visit user_settings_active_sessions_path

            within('.settings-section') do
              expect(page).to have_content('with Admin Mode')
              expect(page).not_to have_content('with Step-up Authentication')
            end
          end
        end
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

        expect(page).to have_content('Sign in or sign up before continuing.')
      end
    end
  end
end
