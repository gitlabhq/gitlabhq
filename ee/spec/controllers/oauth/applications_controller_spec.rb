require 'spec_helper'

describe Oauth::ApplicationsController do
  let(:user) { create(:user) }

  context 'project members' do
    before do
      sign_in(user)
    end

    describe 'POST #create' do
      it 'logs the audit event' do
        stub_licensed_features(extended_audit_events: true)

        sign_in(user)

        application = build(:oauth_application)
        application_attributes = application.attributes.merge(scopes: [])

        expect { post :create, doorkeeper_application: application_attributes }.to change { SecurityEvent.count }.by(1)
      end
    end
  end
end
