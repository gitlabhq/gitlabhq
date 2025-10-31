# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsHelper, feature_category: :system_access do
  include Devise::Test::ControllerHelpers

  describe '#unconfirmed_email?' do
    it 'returns true when the flash alert contains a devise failure unconfirmed message' do
      flash[:alert] = t(:unconfirmed, scope: [:devise, :failure])
      expect(helper.unconfirmed_email?).to be_truthy
    end

    it 'returns false when the flash alert does not contain a devise failure unconfirmed message' do
      flash[:alert] = 'something else'
      expect(helper.unconfirmed_email?).to be_falsey
    end
  end

  describe '#verification_data' do
    let(:user) { build_stubbed(:user) }

    context 'when user is not permitted to skip email otp' do
      it 'returns the expected data with skip_path being nil' do
        expect(helper.verification_data(user)).to match({
          username: user.username,
          obfuscated_email: obfuscated_email(user.email),
          verify_path: helper.session_path(:user),
          resend_path: users_resend_verification_code_path,
          skip_path: nil
        })
      end
    end

    context 'when user is permitted to skip email otp' do
      before do
        allow(helper).to receive(
          :permitted_to_skip_email_otp_in_grace_period?
        ).and_return(true)
      end

      it 'returns the expected data with skip_path being the correct route' do
        expect(helper.verification_data(user)).to match({
          username: user.username,
          obfuscated_email: obfuscated_email(user.email),
          verify_path: helper.session_path(:user),
          resend_path: users_resend_verification_code_path,
          skip_path: users_skip_verification_for_now_path
        })
      end
    end
  end

  describe '#obfuscated_email' do
    let(:email) { 'mail@example.com' }

    subject { helper.obfuscated_email(email) }

    it 'delegates to Gitlab::Utils::Email.obfuscated_email' do
      expect(Gitlab::Utils::Email).to receive(:obfuscated_email).with(email).and_call_original

      expect(subject).to eq('ma**@e******.com')
    end
  end

  describe '#session_expire_modal_data' do
    before do
      allow(Gitlab::Auth::SessionExpireFromInitEnforcer).to receive(:session_expires_at).and_return(5)
    end

    subject { helper.session_expire_modal_data }

    it 'returns the expected data' do
      expect(subject).to match(a_hash_including({
        session_timeout: 5000,
        sign_in_url: a_string_including(/^http/)
      }))
    end
  end

  describe '#remember_me_enabled?' do
    subject { helper.remember_me_enabled? }

    context 'when application setting is enabled' do
      before do
        stub_application_setting(remember_me_enabled: true, session_expire_from_init: false)
      end

      it { is_expected.to be true }

      context 'and session_expire_from_init is enabled' do
        before do
          stub_application_setting(session_expire_from_init: true)
        end

        it { is_expected.to be false }
      end
    end

    context 'when application setting is disabled' do
      before do
        stub_application_setting(remember_me_enabled: false)
      end

      it { is_expected.to be false }
    end
  end

  describe '#fallback_to_email_otp_permitted?' do
    let(:user) { build_stubbed(:user) }

    context 'when email_based_mfa feature flag is disabled' do
      before do
        stub_feature_flags(email_based_mfa: false)
      end

      it 'returns false' do
        expect(helper.fallback_to_email_otp_permitted?(user)).to be false
      end
    end

    context 'when email_based_mfa feature flag is enabled' do
      before do
        stub_feature_flags(email_based_mfa: user)
      end

      context 'when user has email_otp_required_after set to nil' do
        let(:user) { build_stubbed(:user, email_otp_required_after: nil) }

        it 'returns false' do
          expect(helper.fallback_to_email_otp_permitted?(user)).to be_falsy
        end
      end

      context 'when user has email_otp_required_after set to future date' do
        let(:user) do
          build_stubbed(:user, email_otp_required_after: Time.zone.today + 1.day)
        end

        it 'returns false' do
          expect(helper.fallback_to_email_otp_permitted?(user)).to be false
        end
      end

      context 'when user has email_otp_required_after set to today' do
        let(:user) { build_stubbed(:user, email_otp_required_after: Time.zone.today) }

        it 'returns true' do
          expect(helper.fallback_to_email_otp_permitted?(user)).to be true
        end
      end

      context 'when user has email_otp_required_after set to past date' do
        let(:user) { build_stubbed(:user, email_otp_required_after: Time.zone.today - 1.day) }

        it 'returns true' do
          expect(helper.fallback_to_email_otp_permitted?(user)).to be true
        end
      end
    end
  end

  describe '#webauthn_authentication_data' do
    let(:user) { build_stubbed(:user) }
    let(:params) { { user: { remember_me: 1 } } }
    let(:remember_me_enabled) { true }

    before do
      allow(helper).to receive(:remember_me_enabled?).and_return(remember_me_enabled)
    end

    context 'when admin_mode is false' do
      it 'returns correct target_path' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:target_path]).to eq(user_session_path)
      end

      it 'returns render_remember_me as true when remember_me is enabled' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:render_remember_me]).to eq('true')
      end

      it 'returns remember_me value from params' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:remember_me]).to eq(1)
      end
    end

    context 'when admin_mode is true' do
      it 'returns admin session path as target_path' do
        data = helper.webauthn_authentication_data(user: user, params: params, admin_mode: true)

        expect(data[:target_path]).to eq(admin_session_path)
      end

      it 'returns render_remember_me as false' do
        data = helper.webauthn_authentication_data(user: user, params: params, admin_mode: true)

        expect(data[:render_remember_me]).to eq('false')
      end
    end

    context 'when remember_me is disabled' do
      let(:remember_me_enabled) { false }

      it 'returns render_remember_me as false' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:render_remember_me]).to eq('false')
      end
    end

    context 'when user params is not present' do
      let(:params) { {} }

      it 'returns default remember_me value of 0' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:remember_me]).to eq(0)
      end
    end

    context 'when fallback_to_email_otp is permitted' do
      before do
        allow(helper).to receive(:fallback_to_email_otp_permitted?).and_return(true)
        allow(helper).to receive(:verification_data).with(user).and_return({
          username: user.username,
          obfuscated_email: 'u***@example.com',
          verify_path: '/verify',
          resend_path: '/resend',
          skip_path: nil
        })
      end

      it 'includes send_email_otp_path' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:send_email_otp_path]).to eq(users_fallback_to_email_otp_path)
      end

      it 'includes username' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:username]).to eq(user.username)
      end

      it 'includes email_verification_data as JSON' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:email_verification_data]).to be_present
        parsed_data = Gitlab::Json.parse(data[:email_verification_data])
        expect(parsed_data['username']).to eq(user.username)
        expect(parsed_data['obfuscatedEmail']).to eq('u***@example.com')
      end
    end

    context 'when fallback_to_email_otp is not permitted' do
      before do
        allow(helper).to receive(:fallback_to_email_otp_permitted?).and_return(false)
      end

      it 'does not include send_email_otp_path' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:send_email_otp_path]).to be_nil
      end

      it 'includes username' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data[:username]).to eq(user.username)
      end

      it 'does not include email_verification_data' do
        data = helper.webauthn_authentication_data(user: user, params: params)

        expect(data.key?(:email_verification_data)).to be false
      end
    end
  end
end
