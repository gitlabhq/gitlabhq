# frozen_string_literal: true

require 'spec_helper'

describe RecaptchaExperimentHelper, type: :helper do
  let(:session) { {} }

  before do
    allow(helper).to receive(:session) { session }
  end

  describe '.show_recaptcha_sign_up?' do
    context 'when reCAPTCHA is disabled' do
      it 'returns false' do
        stub_application_setting(recaptcha_enabled: false)

        expect(helper.show_recaptcha_sign_up?).to be(false)
      end
    end

    context 'when reCAPTCHA is enabled' do
      it 'returns true' do
        stub_application_setting(recaptcha_enabled: true)

        expect(helper.show_recaptcha_sign_up?).to be(true)
      end
    end
  end
end
