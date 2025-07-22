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

    it 'returns the expected data' do
      expect(helper.verification_data(user)).to eq({
        username: user.username,
        obfuscated_email: obfuscated_email(user.email),
        verify_path: helper.session_path(:user),
        resend_path: users_resend_verification_code_path
      })
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

      context 'and session_expire_from_init FF is disabled' do
        before do
          stub_feature_flags(session_expire_from_init: false)
        end

        it { is_expected.to be true }
      end

      context 'and session_expire_from_init is enabled' do
        before do
          stub_application_setting(session_expire_from_init: true)
        end

        it { is_expected.to be false }

        context 'and session_expire_from_init FF is disabled' do
          before do
            stub_feature_flags(session_expire_from_init: false)
          end

          it { is_expected.to be true }
        end
      end
    end

    context 'when application setting is disabled' do
      before do
        stub_application_setting(remember_me_enabled: false)
      end

      it { is_expected.to be false }
    end
  end
end
