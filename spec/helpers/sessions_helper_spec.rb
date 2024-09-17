# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsHelper, feature_category: :system_access do
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

  describe '#unconfirmed_verification_email?', :freeze_time do
    using RSpec::Parameterized::TableSyntax

    let(:user) { build_stubbed(:user) }
    let(:token_valid_for) { ::Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES }

    subject { helper.unconfirmed_verification_email?(user) }

    where(:reset_first_offer?, :unconfirmed_email_present?, :token_valid?, :result) do
      true  | true  | true  | true
      false | true  | true  | false
      true  | false | true  | false
      true  | true  | false | false
    end

    with_them do
      before do
        user.email_reset_offered_at = 1.minute.ago unless reset_first_offer?
        user.unconfirmed_email = 'unconfirmed@email' if unconfirmed_email_present?
        user.confirmation_sent_at = (token_valid? ? token_valid_for - 1 : token_valid_for + 1).minutes.ago
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#verification_email' do
    let(:unconfirmed_email) { 'unconfirmed@email' }
    let(:user) { build_stubbed(:user, unconfirmed_email: unconfirmed_email) }

    subject { helper.verification_email(user) }

    context 'when there is an unconfirmed verification email' do
      before do
        allow(helper).to receive(:unconfirmed_verification_email?).and_return(true)
      end

      it { is_expected.to eq(unconfirmed_email) }
    end

    context 'when there is no unconfirmed verification email' do
      before do
        allow(helper).to receive(:unconfirmed_verification_email?).and_return(false)
      end

      it { is_expected.to eq(user.email) }
    end
  end

  describe '#verification_data' do
    let(:user) { build_stubbed(:user) }

    it 'returns the expected data' do
      expect(helper.verification_data(user)).to eq({
        username: user.username,
        obfuscated_email: obfuscated_email(user.email),
        verify_path: helper.session_path(:user),
        resend_path: users_resend_verification_code_path,
        offer_email_reset: user.email_reset_offered_at.nil?.to_s,
        update_email_path: users_update_email_path
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

  describe '#remember_me_enabled?' do
    subject { helper.remember_me_enabled? }

    context 'when application setting is enabled' do
      before do
        stub_application_setting(remember_me_enabled: true)
      end

      it { is_expected.to be true }
    end

    context 'when application setting is disabled' do
      before do
        stub_application_setting(remember_me_enabled: false)
      end

      it { is_expected.to be false }
    end
  end
end
