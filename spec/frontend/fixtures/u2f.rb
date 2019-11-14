# frozen_string_literal: true

require 'spec_helper'

context 'U2F' do
  include JavaScriptFixturesHelpers

  let(:user) { create(:user, :two_factor_via_u2f, otp_secret: 'otpsecret:coolkids') }

  before(:all) do
    clean_frontend_fixtures('u2f/')
  end

  describe SessionsController, '(JavaScript fixtures)', type: :controller do
    include DeviseHelpers

    render_views

    before do
      set_devise_mapping(context: @request)
    end

    it 'u2f/authenticate.html' do
      allow(controller).to receive(:find_user).and_return(user)

      post :create, params: { user: { login: user.username, password: user.password } }

      expect(response).to be_successful
    end
  end

  describe Profiles::TwoFactorAuthsController, '(JavaScript fixtures)', type: :controller do
    render_views

    before do
      sign_in(user)
      allow_next_instance_of(Profiles::TwoFactorAuthsController) do |instance|
        allow(instance).to receive(:build_qr_code).and_return('qrcode:blackandwhitesquares')
      end
    end

    it 'u2f/register.html' do
      get :show

      expect(response).to be_successful
    end
  end
end
