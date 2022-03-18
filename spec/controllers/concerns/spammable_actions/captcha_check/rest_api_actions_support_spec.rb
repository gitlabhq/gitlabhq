# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SpammableActions::CaptchaCheck::RestApiActionsSupport do
  include Rack::Test::Methods

  subject do
    Class.new(Grape::API) do
      helpers API::Helpers
      helpers SpammableActions::CaptchaCheck::RestApiActionsSupport

      get ':id' do
        # NOTE: This was the only way that seemed to work to inject the mock spammable into the
        # Grape rack app instance. If there's a better way, improvements are welcome.
        spammable = Object.fake_spammable_factory
        with_captcha_check_rest_api(spammable: spammable) do
          render_api_error!(spammable.errors, 400)
        end
      end
    end
  end

  def app
    subject
  end

  before do
    allow(Gitlab::Recaptcha).to receive(:load_configurations!) { true }
  end

  describe '#with_captcha_check_json_format' do
    let(:spammable) { instance_double(Snippet) }

    before do
      expect(spammable).to receive(:render_recaptcha?).at_least(:once) { render_recaptcha }
      allow(Object).to receive(:fake_spammable_factory) { spammable }
    end

    context 'when spammable.render_recaptcha? is true' do
      let(:render_recaptcha) { true }
      let(:spam_log) { instance_double(SpamLog, id: 1) }
      let(:spammable) { instance_double(Snippet, spam?: true, render_recaptcha?: render_recaptcha, spam_log: spam_log) }
      let(:recaptcha_site_key) { 'abc123' }
      let(:err_msg) { 'You gotta solve the CAPTCHA' }
      let(:spam_action_response_fields) do
        {
          spam: true,
          needs_captcha_response: render_recaptcha,
          spam_log_id: 1,
          captcha_site_key: recaptcha_site_key
        }
      end

      it 'renders json containing spam_action_response_fields' do
        allow(spammable).to receive_message_chain('errors.full_messages.to_sentence') { err_msg }
        allow(Gitlab::CurrentSettings).to receive(:recaptcha_site_key) { recaptcha_site_key }
        response = get '/test'
        expected_response = {
          'needs_captcha_response' => render_recaptcha,
          'spam_log_id' => 1,
          'captcha_site_key' => recaptcha_site_key,
          'message' => { 'error' => err_msg }
        }
        expect(Gitlab::Json.parse(response.body)).to eq(expected_response)
        expect(response.status).to eq(409)
      end
    end

    context 'when spammable.render_recaptcha? is false' do
      let(:render_recaptcha) { false }
      let(:errors) { { 'base' => "It's definitely spam" } }

      it 'yields to block' do
        allow(spammable).to receive(:errors) { errors }

        response = get 'test'
        expected_response = {
          'message' => errors
        }
        expect(Gitlab::Json.parse(response.body)).to eq(expected_response)
        expect(response.status).to eq(400)
      end
    end
  end
end
