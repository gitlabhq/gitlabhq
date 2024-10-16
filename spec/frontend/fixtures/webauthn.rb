# frozen_string_literal: true

require 'spec_helper'

RSpec.context 'WebAuthn' do
  include JavaScriptFixturesHelpers

  let(:user) { create(:user, :two_factor_via_webauthn, otp_secret: 'otpsecret:coolkids') }

  describe SessionsController, '(JavaScript fixtures)', type: :controller do
    include DeviseHelpers

    render_views

    before do
      set_devise_mapping(context: @request)
    end

    it 'webauthn/authenticate.html' do
      allow(controller).to receive(:find_user).and_return(user)
      post :create, params: { user: { login: user.username, password: user.password } }

      expect(response).to be_successful
    end
  end
end
