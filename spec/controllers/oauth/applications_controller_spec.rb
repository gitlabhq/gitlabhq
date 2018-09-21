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

      it 'shows list of applications' do
        disable_user_oauth

        get :index

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'POST #create' do
      it 'creates an application' do
        post :create, oauth_params

        expect(response).to have_gitlab_http_status(302)
        expect(response).to redirect_to(oauth_application_path(Doorkeeper::Application.last))
      end

      it 'redirects back to profile page if OAuth applications are disabled' do
        disable_user_oauth

        post :create, oauth_params

        expect(response).to have_gitlab_http_status(302)
        expect(response).to redirect_to(profile_path)
      end
    end
  end

  def disable_user_oauth
    allow(Gitlab::CurrentSettings.current_application_settings).to receive(:user_oauth_applications?).and_return(false)
  end

  def oauth_params
    {
      doorkeeper_application: {
        name: 'foo',
        redirect_uri: 'http://example.org'
      }
    }
  end
end
