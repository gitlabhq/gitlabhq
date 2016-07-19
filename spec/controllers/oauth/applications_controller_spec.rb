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

        expect(response).to have_http_status(200)
      end

      it 'redirects back to profile page if OAuth applications are disabled' do
        settings = double(user_oauth_applications?: false)
        allow_any_instance_of(Gitlab::CurrentSettings).to receive(:current_application_settings).and_return(settings)

        get :index

        expect(response).to have_http_status(302)
        expect(response).to redirect_to(profile_path)
      end
    end
  end
end
