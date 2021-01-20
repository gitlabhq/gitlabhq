# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SpammableActions do
  controller(ActionController::Base) do
    include SpammableActions

    # #create is used to test spammable_params
    # for testing purposes
    def create
      spam_params = spammable_params

      # replace the actual request with a string in the JSON response, all we care is that it got set
      spam_params[:request] = 'this is the request' if spam_params[:request]

      # just return the params in the response so they can be verified in this fake controller spec.
      # Normally, they are processed further by the controller action
      render json: spam_params.to_json, status: :ok
    end

    # #update is used to test recaptcha_check_with_fallback
    # for testing purposes
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
    # Ordinarily we would not stub a method on the class under test, but :ensure_spam_config_loaded!
    # returns false in the test environment, and is also strong_memoized, so we need to stub it
    allow(controller).to receive(:ensure_spam_config_loaded!) { true }
  end

  describe '#spammable_params' do
    subject { post :create, format: :json, params: params }

    shared_examples 'expects request param only' do
      it do
        subject

        expect(response).to be_successful
        expect(json_response).to eq({ 'request' => 'this is the request' })
      end
    end

    shared_examples 'expects all spammable params' do
      it do
        subject

        expect(response).to be_successful
        expect(json_response['request']).to eq('this is the request')
        expect(json_response['recaptcha_verified']).to eq(true)
        expect(json_response['spam_log_id']).to eq('1')
      end
    end

    let(:recaptcha_response) { nil }
    let(:spam_log_id) { nil }

    context 'when recaptcha response is not present' do
      let(:params) do
        {
          spam_log_id: spam_log_id
        }
      end

      it_behaves_like 'expects request param only'
    end

    context 'when recaptcha response is present' do
      let(:recaptcha_response) { 'abd123' }
      let(:params) do
        {
          'g-recaptcha-response': recaptcha_response,
          spam_log_id: spam_log_id
        }
      end

      context 'when verify_recaptcha returns falsey' do
        before do
          expect(controller).to receive(:verify_recaptcha).with(
            {
              response: recaptcha_response
            }) { false }
        end

        it_behaves_like 'expects request param only'
      end

      context 'when verify_recaptcha returns truthy' do
        let(:spam_log_id) { 1 }

        before do
          expect(controller).to receive(:verify_recaptcha).with(
            {
              response: recaptcha_response
            }) { true }
        end

        it_behaves_like 'expects all spammable params'
      end
    end
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

      # NOTE: Not adding coverage of details of render_recaptcha?, the plan is to refactor it out
      # of this module anyway as part of adding support for the GraphQL reCAPTCHA flow.

      context 'when render_recaptcha? is true' do
        before do
          expect(controller).to receive(:render_recaptcha?) { true }
        end

        context 'when format is :html' do
          it 'renders :verify' do
            expect(controller).to receive(:render).with(:verify)

            subject
          end
        end

        context 'when format is :json' do
          let(:format) { :json }
          let(:recaptcha_html) { '<recaptcha-html/>' }

          it 'renders json with recaptcha_html' do
            expect(controller).to receive(:render_to_string).with(
              {
                partial: 'shared/recaptcha_form',
                formats: :html,
                locals: {
                  spammable: spammable,
                  script: false,
                  has_submit: false
                }
              }
            ) { recaptcha_html }

            subject

            expect(json_response).to eq({ 'recaptcha_html' => recaptcha_html })
          end
        end
      end
    end
  end
end
