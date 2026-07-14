# frozen_string_literal: true

require 'spec_helper'

RSpec.context 'WebAuthn', feature_category: :system_access do
  include JavaScriptFixturesHelpers

  let(:user) { create(:user, :two_factor_via_webauthn, otp_secret: 'otpsecret:coolkids') }

  describe SessionsController, '(JavaScript fixtures)', type: :controller do
    include DeviseHelpers

    render_views

    before do
      set_devise_mapping(context: @request)
      # This fixture feeds the legacy WebAuthn component spec, which un-hides the HAML
      # `.js-2fa-form`. With :two_factor_vue on, WebAuthn users render the Vue mount instead
      # and the form is absent, so pin the flag off to keep generating the legacy markup.
      stub_feature_flags(two_factor_vue: false)
    end

    it 'webauthn/authenticate.html', feature_category: :system_access do
      allow(controller).to receive(:find_user).and_return(user)
      post :create, params: { user: { login: user.username, password: user.password } }

      expect(response).to be_successful
    end
  end
end
