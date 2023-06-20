# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::WebauthnRegistrationsController do
  let(:user) { create(:user, :two_factor_via_webauthn) }

  before do
    sign_in(user)
  end

  describe '#destroy' do
    let(:webauthn_id) { user.webauthn_registrations.first.id }

    subject { delete :destroy, params: { id: webauthn_id } }

    it 'redirects to the profile two factor authentication page' do
      subject

      expect(response).to redirect_to profile_two_factor_auth_path
    end

    it 'destroys the webauthn registration' do
      expect { subject }.to change { user.webauthn_registrations.count }.by(-1)
    end

    it 'calls the Webauthn::DestroyService' do
      service = double

      expect(Webauthn::DestroyService).to receive(:new).with(user, user, webauthn_id.to_s).and_return(service)
      expect(service).to receive(:execute)

      subject
    end
  end
end
