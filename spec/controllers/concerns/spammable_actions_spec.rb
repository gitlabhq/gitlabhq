# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SpammableActions do
  controller(ActionController::Base) do
    include SpammableActions

    # #update is used here to test #recaptcha_check_with_fallback, but it could be invoked
    # from #create or any other action which mutates a spammable via a controller.
    def update
      should_redirect = params[:should_redirect] == 'true'

      recaptcha_check_with_fallback(should_redirect) { render json: :ok }
    end

    private

    def spammable_path
      '/fake_spammable_path'
    end
  end

  before do
    allow(Gitlab::Recaptcha).to receive(:load_configurations!) { true }
  end

  describe '#recaptcha_check_with_fallback' do
    shared_examples 'yields to block' do
      it do
        subject

        expect(json_response).to eq({ json: 'ok' })
      end
    end

    let(:format) { :html }

    subject { post :update, format: format, params: params }

    let(:spammable) { double(:spammable) }
    let(:should_redirect) { nil }
    let(:params) do
      {
        should_redirect: should_redirect
      }
    end

    before do
      routes.draw { get 'update' => 'anonymous#update' }
      allow(controller).to receive(:spammable) { spammable }
    end

    context 'when should_redirect is true and spammable is valid' do
      let(:should_redirect) { true }

      before do
        allow(spammable).to receive(:valid?) { true }
      end

      it 'redirects to spammable_path' do
        expect(subject).to redirect_to('/fake_spammable_path')
      end
    end

    context 'when should_redirect is false or spammable is not valid' do
      before do
        allow(spammable).to receive(:valid?) { false }
      end

      context 'when spammable.render_recaptcha? is true' do
        let(:spam_log) { instance_double(SpamLog, id: 123) }
        let(:captcha_site_key) { 'abc123' }

        before do
          expect(spammable).to receive(:render_recaptcha?).at_least(:once) { true }
        end

        context 'when format is :html' do
          it 'renders :verify' do
            expect(controller).to receive(:render).with(:verify)

            subject
          end
        end

        context 'when format is :json' do
          let(:format) { :json }

          before do
            expect(spammable).to receive(:spam?) { false }
            expect(spammable).to receive(:spam_log) { spam_log }
            expect(Gitlab::CurrentSettings).to receive(:recaptcha_site_key) { captcha_site_key }
          end

          it 'renders json with spam_action_response_fields' do
            subject

            expected_json_response = HashWithIndifferentAccess.new(
              {
                spam: false,
                needs_captcha_response: true,
                spam_log_id: spam_log.id,
                captcha_site_key: captcha_site_key
              })
            expect(json_response).to eq(expected_json_response)
          end
        end
      end
    end
  end
end
