# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RecaptchaHelper, type: :helper do
  let(:session) { {} }

  before do
    allow(helper).to receive(:session) { session }
  end

  shared_examples 'Gitlab QA bypass' do
    context 'when GITLAB_QA_USER_AGENT env var is present' do
      using RSpec::Parameterized::TableSyntax

      where(:dot_com, :user_agent, :qa_user_agent, :result) do
        false | 'qa_user_agent' | 'qa_user_agent' | true
        true  | nil             | 'qa_user_agent' | true
        true  | ''              | 'qa_user_agent' | true
        true  | 'qa_user_agent' | ''              | true
        true  | 'qa_user_agent' | nil             | true
        true  | 'qa_user_agent' | 'qa_user_agent' | false
      end

      with_them do
        before do
          allow(Gitlab).to receive(:com?).and_return(dot_com)
          stub_env('GITLAB_QA_USER_AGENT', qa_user_agent)

          request_double = instance_double(ActionController::TestRequest, user_agent: user_agent)
          allow(helper).to receive(:request).and_return(request_double)
        end

        it { is_expected.to eq result }
      end
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
