# frozen_string_literal: true

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
        disable_user_oauth

        get :index

        expect(response).to have_gitlab_http_status(200)
      end
    end

    describe 'POST #create' do
      it 'creates an application' do
        post :create, params: oauth_params

        expect(response).to have_gitlab_http_status(302)
        expect(response).to redirect_to(oauth_application_path(Doorkeeper::Application.last))
      end

      it 'redirects back to profile page if OAuth applications are disabled' do
        disable_user_oauth

        post :create, params: oauth_params

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

          post :create, params: invalid_uri_params

          expect(response.body).to include 'Redirect URI is forbidden by the server'
        end
      end
    end
  end

  context 'Helpers' do
    it 'current_user_mode available' do
      expect(subject.current_user_mode).not_to be_nil
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
