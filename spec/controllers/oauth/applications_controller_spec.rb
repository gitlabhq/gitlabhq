# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::ApplicationsController do
  let(:user) { create(:user) }
  let(:application) { create(:oauth_application, owner: user) }

  context 'project members' do
    before do
      sign_in(user)
    end

    shared_examples 'redirects to login page when the user is not signed in' do
      before do
        sign_out(user)
      end

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    describe 'GET #new' do
      subject { get :new }

      it { is_expected.to have_gitlab_http_status(:ok) }

      it_behaves_like 'redirects to login page when the user is not signed in'
    end

    describe 'DELETE #destroy' do
      subject { delete :destroy, params: { id: application.id } }

      it { is_expected.to redirect_to(oauth_applications_url) }

      it_behaves_like 'redirects to login page when the user is not signed in'
    end

    describe 'GET #edit' do
      subject { get :edit, params: { id: application.id } }

      it { is_expected.to have_gitlab_http_status(:ok) }

      it_behaves_like 'redirects to login page when the user is not signed in'
    end

    describe 'PUT #update' do
      subject { put :update, params: { id: application.id, doorkeeper_application: { name: 'application' } } }

      it { is_expected.to redirect_to(oauth_application_url(application)) }

      it_behaves_like 'redirects to login page when the user is not signed in'
    end

    describe 'GET #show' do
      subject { get :show, params: { id: application.id } }

      it { is_expected.to have_gitlab_http_status(:ok) }

      it_behaves_like 'redirects to login page when the user is not signed in'
    end

    describe 'GET #index' do
      subject { get :index }

      it { is_expected.to have_gitlab_http_status(:ok) }

      context 'when OAuth applications are disabled' do
        before do
          disable_user_oauth
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
      end

      it_behaves_like 'redirects to login page when the user is not signed in'
    end

    describe 'POST #create' do
      subject { post :create, params: oauth_params }

      it 'creates an application' do
        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(oauth_application_path(Doorkeeper::Application.last))
      end

      it 'redirects back to profile page if OAuth applications are disabled' do
        disable_user_oauth

        subject

        expect(response).to have_gitlab_http_status(:found)
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

      it_behaves_like 'redirects to login page when the user is not signed in'
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
