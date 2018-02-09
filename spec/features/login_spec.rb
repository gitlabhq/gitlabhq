require 'spec_helper'

feature 'Login' do
  describe 'initial login after setup' do
    it 'allows the initial admin to create a password' do
      # This behavior is dependent on there only being one user
      User.delete_all

      user = create(:admin, password_automatically_set: true)

      visit root_path
      expect(current_path).to eq edit_user_password_path
      expect(page).to have_content('Please create a password for your new account.')

      fill_in 'user_password',              with: 'password'
      fill_in 'user_password_confirmation', with: 'password'
      click_button 'Change your password'

      expect(current_path).to eq new_user_session_path
      expect(page).to have_content(I18n.t('devise.passwords.updated_not_active'))

      fill_in 'user_login',    with: user.username
      fill_in 'user_password', with: 'password'
      click_button 'Sign in'

      expect(current_path).to eq root_path
    end

    it 'does not show flash messages when login page' do
      visit root_path
      expect(page).not_to have_content('You need to sign in or sign up before continuing.')
    end
  end

  describe 'with a blocked account' do
    it 'prevents the user from logging in' do
      user = create(:user, :blocked)

      gitlab_sign_in(user)

      expect(page).to have_content('Your account has been blocked.')
    end

    it 'does not update Devise trackable attributes', :clean_gitlab_redis_shared_state do
      user = create(:user, :blocked)

      expect { gitlab_sign_in(user) }.not_to change { user.reload.sign_in_count }
    end
  end

  describe 'with the ghost user' do
    it 'disallows login' do
      gitlab_sign_in(User.ghost)

      expect(page).to have_content('Invalid Login or password.')
    end

    it 'does not update Devise trackable attributes', :clean_gitlab_redis_shared_state do
      expect { gitlab_sign_in(User.ghost) }.not_to change { User.ghost.reload.sign_in_count }
    end
  end

  describe 'with two-factor authentication' do
    def enter_code(code)
      fill_in 'user_otp_attempt', with: code
      click_button 'Verify code'
    end

    context 'with valid username/password' do
      let(:user) { create(:user, :two_factor) }

      before do
        gitlab_sign_in(user, remember: true)
        expect(page).to have_content('Two-Factor Authentication')
      end

      it 'does not show a "You are already signed in." error message' do
        enter_code(user.current_otp)
        expect(page).not_to have_content('You are already signed in.')
      end

      context 'using one-time code' do
        it 'allows login with valid code' do
          enter_code(user.current_otp)
          expect(current_path).to eq root_path
        end

        it 'persists remember_me value via hidden field' do
          field = first('input#user_remember_me', visible: false)

          expect(field.value).to eq '1'
        end

        it 'blocks login with invalid code' do
          enter_code('foo')
          expect(page).to have_content('Invalid two-factor code')
        end

        it 'allows login with invalid code, then valid code' do
          enter_code('foo')
          expect(page).to have_content('Invalid two-factor code')

          enter_code(user.current_otp)
          expect(current_path).to eq root_path
        end
      end

      context 'using backup code' do
        let(:codes) { user.generate_otp_backup_codes! }

        before do
          expect(codes.size).to eq 10

          # Ensure the generated codes get saved
          user.save
        end

        context 'with valid code' do
          it 'allows login' do
            enter_code(codes.sample)
            expect(current_path).to eq root_path
          end

          it 'invalidates the used code' do
            expect { enter_code(codes.sample) }
              .to change { user.reload.otp_backup_codes.size }.by(-1)
          end

          it 'invalidates backup codes twice in a row' do
            random_code = codes.delete(codes.sample)
            expect { enter_code(random_code) }
              .to change { user.reload.otp_backup_codes.size }.by(-1)

            gitlab_sign_out
            gitlab_sign_in(user)

            expect { enter_code(codes.sample) }
              .to change { user.reload.otp_backup_codes.size }.by(-1)
          end
        end

        context 'with invalid code' do
          it 'blocks login' do
            code = codes.sample
            expect(user.invalidate_otp_backup_code!(code)).to eq true

            user.save!
            expect(user.reload.otp_backup_codes.size).to eq 9

            enter_code(code)
            expect(page).to have_content('Invalid two-factor code.')
          end
        end
      end
    end

    context 'logging in via OAuth' do
      it 'shows 2FA prompt after OAuth login' do
        stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'], providers: [mock_saml_config])
        user = create(:omniauth_user, :two_factor, extern_uid: 'my-uid', provider: 'saml')
        gitlab_sign_in_via('saml', user, 'my-uid')

        expect(page).to have_content('Two-Factor Authentication')
        enter_code(user.current_otp)
        expect(current_path).to eq root_path
      end
    end
  end

  describe 'without two-factor authentication' do
    let(:user) { create(:user) }

    it 'allows basic login' do
      gitlab_sign_in(user)
      expect(current_path).to eq root_path
    end

    it 'does not show a "You are already signed in." error message' do
      gitlab_sign_in(user)
      expect(page).not_to have_content('You are already signed in.')
    end

    it 'blocks invalid login' do
      user = create(:user, password: 'not-the-default')

      gitlab_sign_in(user)
      expect(page).to have_content('Invalid Login or password.')
    end
  end

  describe 'with required two-factor authentication enabled' do
    let(:user) { create(:user) }
    #  TODO: otp_grace_period_started_at

    context 'global setting' do
      before do
        stub_application_setting(require_two_factor_authentication: true)
      end

      context 'with grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 48)
          gitlab_sign_in(user)
        end

        context 'within the grace period' do
          it 'redirects to two-factor configuration page' do
            expect(current_path).to eq profile_two_factor_auth_path
            expect(page).to have_content('The global settings require you to enable Two-Factor Authentication for your account. You need to do this before ')
          end

          it 'allows skipping two-factor configuration', :js do
            expect(current_path).to eq profile_two_factor_auth_path

            click_link 'Configure it later'
            expect(current_path).to eq root_path
          end
        end

        context 'after the grace period' do
          let(:user) { create(:user, otp_grace_period_started_at: 9999.hours.ago) }

          it 'redirects to two-factor configuration page' do
            expect(current_path).to eq profile_two_factor_auth_path
            expect(page).to have_content(
              'The global settings require you to enable Two-Factor Authentication for your account.'
            )
          end

          it 'disallows skipping two-factor configuration', :js do
            expect(current_path).to eq profile_two_factor_auth_path
            expect(page).not_to have_link('Configure it later')
          end
        end
      end

      context 'without grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 0)
          gitlab_sign_in(user)
        end

        it 'redirects to two-factor configuration page' do
          expect(current_path).to eq profile_two_factor_auth_path
          expect(page).to have_content(
            'The global settings require you to enable Two-Factor Authentication for your account.'
          )
        end
      end
    end

    context 'group setting' do
      before do
        group1 = create :group, name: 'Group 1', require_two_factor_authentication: true
        group1.add_user(user, GroupMember::DEVELOPER)
        group2 = create :group, name: 'Group 2', require_two_factor_authentication: true
        group2.add_user(user, GroupMember::DEVELOPER)
      end

      context 'with grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 48)
          gitlab_sign_in(user)
        end

        context 'within the grace period' do
          it 'redirects to two-factor configuration page' do
            expect(current_path).to eq profile_two_factor_auth_path
            expect(page).to have_content(
              'The group settings for Group 1 and Group 2 require you to enable ' \
              'Two-Factor Authentication for your account. You need to do this ' \
              'before ')
          end

          it 'allows skipping two-factor configuration', :js do
            expect(current_path).to eq profile_two_factor_auth_path

            click_link 'Configure it later'
            expect(current_path).to eq root_path
          end
        end

        context 'after the grace period' do
          let(:user) { create(:user, otp_grace_period_started_at: 9999.hours.ago) }

          it 'redirects to two-factor configuration page' do
            expect(current_path).to eq profile_two_factor_auth_path
            expect(page).to have_content(
              'The group settings for Group 1 and Group 2 require you to enable ' \
              'Two-Factor Authentication for your account.'
            )
          end

          it 'disallows skipping two-factor configuration', :js do
            expect(current_path).to eq profile_two_factor_auth_path
            expect(page).not_to have_link('Configure it later')
          end
        end
      end

      context 'without grace period defined' do
        before do
          stub_application_setting(two_factor_grace_period: 0)
          gitlab_sign_in(user)
        end

        it 'redirects to two-factor configuration page' do
          expect(current_path).to eq profile_two_factor_auth_path
          expect(page).to have_content(
            'The group settings for Group 1 and Group 2 require you to enable ' \
            'Two-Factor Authentication for your account.'
          )
        end
      end
    end
  end

  describe 'UI tabs and panes' do
    context 'when no defaults are changed' do
      it 'correctly renders tabs and panes' do
        ensure_tab_pane_correctness
      end
    end

    context 'when signup is disabled' do
      before do
        stub_application_setting(signup_enabled: false)
      end

      it 'correctly renders tabs and panes' do
        ensure_tab_pane_correctness
      end
    end

    context 'when ldap is enabled' do
      before do
        visit new_user_session_path
        allow(page).to receive(:form_based_providers).and_return([:ldapmain])
        allow(page).to receive(:ldap_enabled).and_return(true)
      end

      it 'correctly renders tabs and panes' do
        ensure_tab_pane_correctness(false)
      end
    end

    context 'when crowd is enabled' do
      before do
        visit new_user_session_path
        allow(page).to receive(:form_based_providers).and_return([:crowd])
        allow(page).to receive(:crowd_enabled?).and_return(true)
      end

      it 'correctly renders tabs and panes' do
        ensure_tab_pane_correctness(false)
      end
    end

    def ensure_tab_pane_correctness(visit_path = true)
      if visit_path
        visit new_user_session_path
      end

      ensure_tab_pane_counts
      ensure_one_active_tab
      ensure_one_active_pane
    end

    def ensure_tab_pane_counts
      tabs_count = page.all('[role="tab"]').size
      expect(page).to have_selector('[role="tabpanel"]', count: tabs_count)
    end

    def ensure_one_active_tab
      expect(page).to have_selector('.nav-tabs > li.active', count: 1)
    end

    def ensure_one_active_pane
      expect(page).to have_selector('.tab-pane.active', count: 1)
    end
  end
end
