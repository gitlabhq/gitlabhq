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

      context 'redirect_uri' do
        render_views

        it 'shows an error for a forbidden URI' do
          invalid_uri_params = {
            doorkeeper_application: {
              name: 'foo',
              redirect_uri: 'javascript://alert()'
            }
          }

          post :create, invalid_uri_params

          expect(response.body).to include 'Redirect URI is forbidden by the server'
        end
      end
    end
  end
end
