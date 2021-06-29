# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfirmationsController do
  include DeviseHelpers

  before do
    set_devise_mapping(context: @request)
  end

  describe '#show' do
    render_views

    def perform_request
      get :show, params: { confirmation_token: confirmation_token }
    end

    context 'user is already confirmed' do
      let_it_be_with_reload(:user) { create(:user, :unconfirmed) }

      let(:confirmation_token) { user.confirmation_token }

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

      it 'sets the username and caller_id in the context' do
        expect(controller).to receive(:show).and_wrap_original do |m, *args|
          m.call(*args)

          expect(Gitlab::ApplicationContext.current)
            .to include('meta.user' => user.username,
                        'meta.caller_id' => 'ConfirmationsController#show')
        end

        perform_request
      end
    end

    context 'user accesses the link after the expiry of confirmation token has passed' do
      let_it_be_with_reload(:user) { create(:user, :unconfirmed) }

      let(:confirmation_token) { user.confirmation_token }

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

      it 'sets the username and caller_id in the context' do
        expect(controller).to receive(:show).and_wrap_original do |m, *args|
          m.call(*args)

          expect(Gitlab::ApplicationContext.current)
            .to include('meta.user' => user.username,
                        'meta.caller_id' => 'ConfirmationsController#show')
        end

        travel_to(3.days.from_now) { perform_request }
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

      it 'sets the the caller_id in the context' do
        expect(controller).to receive(:show).and_wrap_original do |m, *args|
          expect(Gitlab::ApplicationContext.current)
            .to include('meta.caller_id' => 'ConfirmationsController#show')

          m.call(*args)
        end

        perform_request
      end
    end
  end
end
