require 'spec_helper'

describe Oauth::AuthorizationsController do
  let(:user) { create(:user) }

  let(:doorkeeper) do
    Doorkeeper::Application.create(
      name: "MyApp",
      redirect_uri: 'http://example.com',
      scopes: "")
  end

  let(:params) do
    {
      response_type: "code",
      client_id: doorkeeper.uid,
      redirect_uri: doorkeeper.redirect_uri,
      state: 'state'
    }
  end

  before do
    sign_in(user)
  end

  describe 'GET #new' do
    context 'without valid params' do
      it 'returns 200 code and renders error view' do
        get :new

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template('doorkeeper/authorizations/error')
      end
    end

    context 'with valid params' do
      render_views

      it 'returns 200 code and renders view' do
        get :new, params

        expect(response).to have_gitlab_http_status(200)
        expect(response).to render_template('doorkeeper/authorizations/new')
      end

      it 'deletes session.user_return_to and redirects when skip authorization' do
        doorkeeper.update(trusted: true)
        request.session['user_return_to'] = 'http://example.com'

        get :new, params

        expect(request.session['user_return_to']).to be_nil
        expect(response).to have_gitlab_http_status(302)
      end
    end
  end
end
