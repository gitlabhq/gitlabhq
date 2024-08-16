# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfirmationsController, feature_category: :system_access do
  include DeviseHelpers

  before do
    set_devise_mapping(context: @request)
  end

  describe '#show' do
    let_it_be_with_reload(:user) { create(:user, :unconfirmed) }
    let(:confirmation_token) { user.confirmation_token }

    render_views

    def perform_request
      get :show, params: { confirmation_token: confirmation_token }
    end

    context 'user is already confirmed' do
      before do
        user.confirm
      end

      it 'renders `new`' do
        perform_request

        expect(response).to render_template(:new)
      end

      it 'displays an error message' do
        perform_request

        expect(response.body).to include('Email was already confirmed, please try signing in')
      end

      it 'does not display the email of the user' do
        perform_request

        expect(response.body).not_to include(user.email)
      end
    end

    context 'user accesses the link after the expiry of confirmation token has passed' do
      before do
        allow(Devise).to receive(:confirm_within).and_return(1.day)
      end

      it 'renders `new`' do
        travel_to(3.days.from_now) { perform_request }

        expect(response).to render_template(:new)
      end

      it 'displays an error message' do
        travel_to(3.days.from_now) { perform_request }

        expect(response.body).to include('Email needs to be confirmed within 1 day, please request a new one below')
      end

      it 'does not display the email of the user' do
        travel_to(3.days.from_now) { perform_request }

        expect(response.body).not_to include(user.email)
      end
    end

    context 'with an invalid confirmation token' do
      let(:confirmation_token) { 'invalid_confirmation_token' }

      it 'renders `new`' do
        perform_request

        expect(response).to render_template(:new)
      end

      it 'displays an error message' do
        perform_request

        expect(response.body).to include('Confirmation token is invalid')
      end
    end
  end

  describe '#create' do
    let(:user) { create(:user) }

    subject(:perform_request) { post(:create, params: { user: { email: user.email } }) }

    context "when `email_confirmation_setting` is set to `soft`" do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'soft')
      end

      context 'when reCAPTCHA is disabled' do
        before do
          stub_application_setting(recaptcha_enabled: false)
        end

        it 'successfully sends password reset when reCAPTCHA is not solved' do
          perform_request

          expect(response).to redirect_to(dashboard_projects_path)
        end
      end

      context 'when reCAPTCHA is enabled' do
        before do
          stub_application_setting(recaptcha_enabled: true)
        end

        context 'when the reCAPTCHA is not solved' do
          before do
            Recaptcha.configuration.skip_verify_env.delete('test')
          end

          it 'displays an error' do
            alert_text = _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')

            perform_request

            expect(response).to render_template(:new)
            expect(flash[:alert]).to include alert_text
          end

          it 'sets gon variables' do
            Gon.clear

            perform_request

            expect(response).to render_template(:new)
            expect(Gon.all_variables).not_to be_empty
          end
        end

        it 'successfully sends password reset when reCAPTCHA is solved' do
          Recaptcha.configuration.skip_verify_env << 'test'

          perform_request

          expect(response).to redirect_to(dashboard_projects_path)
        end
      end
    end

    context "when `email_confirmation_setting` is not set to `soft`" do
      it 'redirects to the users_almost_there path' do
        perform_request

        expect(response).to redirect_to(users_almost_there_path)
      end
    end
  end
end
