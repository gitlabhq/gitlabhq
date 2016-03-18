require 'spec_helper'

feature 'Login', feature: true do
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
  end

  describe 'with two-factor authentication' do
    context 'with valid username/password' do
      let(:user) { create(:user, :two_factor) }

      before do
        login_with(user)
        expect(page).to have_content('Two-factor Authentication')
      end

      def enter_code(code)
        fill_in 'Two-factor authentication code', with: code
        click_button 'Verify code'
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
            expect { enter_code(codes.sample) }.
              to change { user.reload.otp_backup_codes.size }.by(-1)
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
  end

  describe 'without two-factor authentication' do
    let(:user) { create(:user) }

    it 'allows basic login' do
      login_with(user)
      expect(current_path).to eq root_path
    end

    it 'does not show a "You are already signed in." error message' do
      login_with(user)
      expect(page).not_to have_content('You are already signed in.')
    end

    it 'blocks invalid login' do
      user = create(:user, password: 'not-the-default')

      login_with(user)
      expect(page).to have_content('Invalid login or password.')
    end
  end

  describe 'with required two-factor authentication enabled' do
    let(:user) { create(:user) }
    before(:each) { stub_application_setting(require_two_factor_authentication: true) }

    context 'with grace period defined' do
      before(:each) do
        stub_application_setting(two_factor_grace_period: 48)
        login_with(user)
      end

      context 'within the grace period' do
        it 'redirects to two-factor configuration page' do
          expect(current_path).to eq new_profile_two_factor_auth_path
          expect(page).to have_content('You must enable Two-factor Authentication for your account before')
        end

        it 'disallows skipping two-factor configuration' do
          expect(current_path).to eq new_profile_two_factor_auth_path

          click_link 'Configure it later'
          expect(current_path).to eq root_path
        end
      end

      context 'after the grace period' do
        let(:user) { create(:user, otp_grace_period_started_at: 9999.hours.ago) }

        it 'redirects to two-factor configuration page' do
          expect(current_path).to eq new_profile_two_factor_auth_path
          expect(page).to have_content('You must enable Two-factor Authentication for your account.')
        end

        it 'disallows skipping two-factor configuration' do
          expect(current_path).to eq new_profile_two_factor_auth_path
          expect(page).not_to have_link('Configure it later')
        end
      end
    end

    context 'without grace pariod defined' do
      before(:each) do
        stub_application_setting(two_factor_grace_period: 0)
        login_with(user)
      end

      it 'redirects to two-factor configuration page' do
        expect(current_path).to eq new_profile_two_factor_auth_path
        expect(page).to have_content('You must enable Two-factor Authentication for your account.')
      end
    end
  end
end
