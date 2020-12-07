# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfirmationsController do
  include DeviseHelpers

  before do
    set_devise_mapping(context: @request)
  end

  describe '#show' do
    render_views

    subject { get :show, params: { confirmation_token: confirmation_token } }

    context 'user is already confirmed' do
      let_it_be_with_reload(:user) { create(:user, :unconfirmed) }
      let(:confirmation_token) { user.confirmation_token }

      before do
        user.confirm
        subject
      end

      it 'renders `new`' do
        expect(response).to render_template(:new)
      end

      it 'displays an error message' do
        expect(response.body).to include('Email was already confirmed, please try signing in')
      end

      it 'does not display the email of the user' do
        expect(response.body).not_to include(user.email)
      end
    end

    context 'user accesses the link after the expiry of confirmation token has passed' do
      let_it_be_with_reload(:user) { create(:user, :unconfirmed) }
      let(:confirmation_token) { user.confirmation_token }

      before do
        allow(Devise).to receive(:confirm_within).and_return(1.day)

        travel_to(3.days.from_now) do
          subject
        end
      end

      it 'renders `new`' do
        expect(response).to render_template(:new)
      end

      it 'displays an error message' do
        expect(response.body).to include('Email needs to be confirmed within 1 day, please request a new one below')
      end

      it 'does not display the email of the user' do
        expect(response.body).not_to include(user.email)
      end
    end

    context 'with an invalid confirmation token' do
      let(:confirmation_token) { 'invalid_confirmation_token' }

      before do
        subject
      end

      it 'renders `new`' do
        expect(response).to render_template(:new)
      end

      it 'displays an error message' do
        expect(response.body).to include('Confirmation token is invalid')
      end
    end
  end
end
