require 'spec_helper'

describe Oauth::ApplicationsController do
  let(:user) { create(:user) }

  context 'project members' do
    before do
      sign_in(user)
    end

    describe 'GET #index' do
      it 'shows list of applications' do
        get :index

        expect(response).to have_gitlab_http_status(200)
      end

      it 'redirects back to profile page if OAuth applications are disabled' do
        allow(Gitlab::CurrentSettings.current_application_settings).to receive(:user_oauth_applications?).and_return(false)

        get :index

        expect(response).to have_gitlab_http_status(302)
        expect(response).to redirect_to(profile_path)
      end
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
