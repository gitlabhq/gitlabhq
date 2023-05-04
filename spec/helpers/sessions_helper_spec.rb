# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsHelper do
  describe '#recently_confirmed_com?' do
    subject { helper.recently_confirmed_com? }

    context 'when on .com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'when flash notice is empty it is false' do
        flash[:notice] = nil
        expect(subject).to be false
      end

      it 'when flash notice is anything it is false' do
        flash[:notice] = 'hooray!'
        expect(subject).to be false
      end

      it 'when flash notice is devise confirmed message it is true' do
        flash[:notice] = t(:confirmed, scope: [:devise, :confirmations])
        expect(subject).to be true
      end
    end

    context 'when not on .com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'when flash notice is devise confirmed message it is false' do
        flash[:notice] = t(:confirmed, scope: [:devise, :confirmations])
        expect(subject).to be false
      end
    end
  end

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

  describe '#send_rate_limited?' do
    let(:user) { build_stubbed(:user) }

    subject { helper.send_rate_limited?(user) }

    before do
      allow(::Gitlab::ApplicationRateLimiter)
        .to receive(:peek)
        .with(:email_verification_code_send, scope: user)
        .and_return(rate_limited)
    end

    context 'when rate limited' do
      let(:rate_limited) { true }

      it { is_expected.to eq(true) }
    end

    context 'when not rate limited' do
      let(:rate_limited) { false }

      it { is_expected.to eq(false) }
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
end
