# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::WebauthnRegistrationsController do
  let(:user) { create(:user, :two_factor_via_webauthn) }

  before do
    sign_in(user)
  end

  describe '#destroy' do
    it 'deletes the given webauthn registration' do
      registration_to_delete = user.webauthn_registrations.first

      expect { delete :destroy, params: { id: registration_to_delete.id } }.to change { user.webauthn_registrations.count }.by(-1)
      expect(response).to be_redirect
    end
  end
end
