# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecaptchaHelper, type: :helper do
  let(:session) { {} }

  before do
    allow(helper).to receive(:session) { session }
  end

  shared_examples 'Gitlab QA bypass' do
    context 'when it is a QA request' do
      before do
        allow(Gitlab::Qa).to receive(:request?).and_return(true)
      end

      it { is_expected.to eq false }
    end
  end

  describe '.show_recaptcha_sign_up?' do
    let(:setting_state) { true }

    before do
      stub_application_setting(recaptcha_enabled: setting_state)
    end

    subject { helper.show_recaptcha_sign_up? }

    it { is_expected.to eq true }

    context 'when setting is disabled' do
      let(:setting_state) { false }

      it { is_expected.to eq false }
    end

    include_examples 'Gitlab QA bypass'
  end

  describe '.recaptcha_enabled_on_login?' do
    let(:setting_state) { true }

    before do
      stub_application_setting(login_recaptcha_protection_enabled: setting_state)
    end

    subject { helper.recaptcha_enabled_on_login? }

    it { is_expected.to eq true }

    context 'when setting is disabled' do
      let(:setting_state) { false }

      it { is_expected.to eq false }
    end

    include_examples 'Gitlab QA bypass'
  end
end
