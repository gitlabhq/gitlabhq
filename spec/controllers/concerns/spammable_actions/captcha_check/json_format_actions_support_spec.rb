# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SpammableActions::CaptchaCheck::JsonFormatActionsSupport do
  controller(ActionController::Base) do
    include SpammableActions::CaptchaCheck::JsonFormatActionsSupport

    def some_action
      with_captcha_check_json_format(spammable: spammable) { render :some_rendered_view }
    end
  end

  before do
    allow(Gitlab::Recaptcha).to receive(:load_configurations!) { true }
  end

  describe '#with_captcha_check_json_format' do
    subject { post :some_action }

    let(:spammable) { double(:spammable) }

    before do
      routes.draw { get 'some_action' => 'anonymous#some_action' }
      allow(controller).to receive(:spammable) { spammable }
      expect(spammable).to receive(:render_recaptcha?).at_least(:once) { render_recaptcha }
    end

    context 'when spammable.render_recaptcha? is true' do
      let(:render_recaptcha) { true }
      let(:spam_log) { double(:spam_log, id: 1) }
      let(:spammable) { double(:spammable, spam?: true, render_recaptcha?: render_recaptcha, spam_log: spam_log) }
      let(:recaptcha_site_key) { 'abc123' }
      let(:spam_action_response_fields) do
        {
          spam: true,
          needs_captcha_response: render_recaptcha,
          spam_log_id: 1,
          captcha_site_key: recaptcha_site_key
        }
      end

      it 'renders json containing spam_action_response_fields' do
        expect(controller).to receive(:render).with(json: spam_action_response_fields, status: :conflict)
        allow(Gitlab::CurrentSettings).to receive(:recaptcha_site_key) { recaptcha_site_key }
        subject
      end
    end

    context 'when spammable.render_recaptcha? is false' do
      let(:render_recaptcha) { false }

      it 'yields to block' do
        expect(controller).to receive(:render).with(:some_rendered_view)

        subject
      end
    end
  end
end
