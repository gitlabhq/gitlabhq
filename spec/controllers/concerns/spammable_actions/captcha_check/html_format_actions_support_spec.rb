# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SpammableActions::CaptchaCheck::HtmlFormatActionsSupport do
  controller(ActionController::Base) do
    include SpammableActions::CaptchaCheck::HtmlFormatActionsSupport

    def create
      with_captcha_check_html_format(spammable: spammable) { render :some_rendered_view }
    end
  end

  let(:spammable) { double(:spammable) }

  before do
    allow(Gitlab::Recaptcha).to receive(:load_configurations!) { true }
    routes.draw { get 'create' => 'anonymous#create' }
    allow(controller).to receive(:spammable) { spammable }
    expect(spammable).to receive(:render_recaptcha?).at_least(:once) { render_recaptcha }
  end

  describe '#convert_html_spam_params_to_headers' do
    let(:render_recaptcha) { false }
    let(:g_recaptcha_response) { 'abc123' }
    let(:spam_log_id) { 42 }

    let(:params) do
      {
        'g-recaptcha-response' => g_recaptcha_response,
        spam_log_id: spam_log_id
      }
    end

    # NOTE: `:update` has an identical `before_action` behavior to ``:create``, but `before_action` is
    # declarative via the ``:only`` attribute, so there's little value in re-testing the behavior.
    subject { post :create, params: params }

    before do
      allow(controller).to receive(:render).with(:some_rendered_view)
    end

    it 'converts params to headers' do
      subject

      expect(controller.request.headers['X-GitLab-Captcha-Response']).to eq(g_recaptcha_response)
      expect(controller.request.headers['X-GitLab-Spam-Log-Id']).to eq(spam_log_id.to_s)
    end
  end

  describe '#with_captcha_check_html_format' do
    subject { post :create }

    context 'when spammable.render_recaptcha? is true' do
      let(:render_recaptcha) { true }

      it 'renders :captcha_check' do
        expect(controller).to receive(:render).with(:captcha_check)

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
