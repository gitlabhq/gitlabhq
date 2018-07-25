# frozen_string_literal: true

require 'spec_helper'

describe ConfirmationsController do
  include DeviseHelpers

  describe 'GET #show' do
    context 'with user' do
      let(:token) { '123456' }
      let(:user) { create(:user, confirmation_token: token, unconfirmed_email: 'test@example.com', confirmation_sent_at: Time.now, confirmed_at: nil) }

      before do
        set_devise_mapping(context: @request)
      end

      it 'confirms user' do
        expect(user.confirmed?).to be_falsey

        get :show, confirmation_token: token

        expect(user.reload.confirmed?).to be_truthy
        expect(response).to have_http_status(302)
      end
    end

    context 'with e-mail' do
      let(:token) { '987654' }
      let(:user) { create(:user) }
      let(:email) { create(:email, user: user, confirmation_token: token, confirmation_sent_at: Time.now, confirmed_at: nil) }

      before do
        set_devise_mapping(context: @request, resource: :email)
      end

      it 'confirms email' do
        expect(email.confirmed?).to be_falsey

        get :show, confirmation_token: token

        expect(email.reload.confirmed?).to be_truthy
        expect(response).to have_http_status(302)
      end
    end
  end
end
