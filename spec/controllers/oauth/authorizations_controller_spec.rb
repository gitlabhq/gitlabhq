# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::AuthorizationsController do
  let!(:application) { create(:oauth_application, scopes: 'api read_user', redirect_uri: 'http://example.com') }
  let(:params) do
    {
      response_type: "code",
      client_id: application.uid,
      redirect_uri: application.redirect_uri,
      state: 'state'
    }
  end

  before do
    sign_in(user)
  end

  describe 'GET #new' do
    context 'when the user is confirmed' do
      let(:user) { create(:user) }

      context 'without valid params' do
        it 'returns 200 code and renders error view' do
          get :new

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/error')
        end
      end

      context 'with valid params' do
        render_views

        it 'returns 200 code and renders view' do
          get :new, params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
        end

        it 'deletes session.user_return_to and redirects when skip authorization' do
          application.update(trusted: true)
          request.session['user_return_to'] = 'http://example.com'

          get :new, params: params

          expect(request.session['user_return_to']).to be_nil
          expect(response).to have_gitlab_http_status(:found)
        end

        context 'when there is already an access token for the application' do
          context 'when the request scope matches any of the created token scopes' do
            before do
              scopes = Doorkeeper::OAuth::Scopes.from_string('api')

              allow(Doorkeeper.configuration).to receive(:scopes).and_return(scopes)

              create :oauth_access_token, application: application, resource_owner_id: user.id, scopes: scopes
            end

            it 'authorizes the request and redirects' do
              get :new, params: params

              expect(request.session['user_return_to']).to be_nil
              expect(response).to have_gitlab_http_status(:found)
            end
          end
        end
      end
    end

    context 'when the user is unconfirmed' do
      let(:user) { create(:user, confirmed_at: nil) }

      it 'returns 200 and renders error view' do
        get :new, params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('doorkeeper/authorizations/error')
      end
    end
  end
end
