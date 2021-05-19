# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::AuthorizationsController do
  let(:user) { create(:user, confirmed_at: confirmed_at) }
  let(:confirmed_at) { 1.hour.ago }
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

  shared_examples 'OAuth Authorizations require confirmed user' do
    context 'when the user is confirmed' do
      context 'when there is already an access token for the application with a matching scope' do
        before do
          scopes = Doorkeeper::OAuth::Scopes.from_string('api')

          allow(Doorkeeper.configuration).to receive(:scopes).and_return(scopes)

          create(:oauth_access_token, application: application, resource_owner_id: user.id, scopes: scopes)
        end

        it 'authorizes the request and redirects' do
          subject

          expect(request.session['user_return_to']).to be_nil
          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end

    context 'when the user is unconfirmed' do
      let(:confirmed_at) { nil }

      it 'returns 200 and renders error view' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('doorkeeper/authorizations/error')
      end
    end
  end

  shared_examples "Implicit grant can't be used in confidential application" do
    context 'when application is confidential' do
      before do
        application.update!(confidential: true)
        params[:response_type] = 'token'
      end

      it 'does not allow the implicit flow' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('doorkeeper/authorizations/error')
      end
    end
  end

  describe 'GET #new' do
    subject { get :new, params: params }

    include_examples 'OAuth Authorizations require confirmed user'
    include_examples "Implicit grant can't be used in confidential application"

    context 'rendering of views based on the ownership of the application' do
      shared_examples 'render views' do
        render_views

        it 'returns 200 and renders view with correct info', :aggregate_failures do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include(application.owner.name)
          expect(response).to render_template('doorkeeper/authorizations/new')
        end
      end

      subject { get :new, params: params }

      context 'when auth app owner is a user' do
        context 'with valid params' do
          it_behaves_like 'render views'
        end
      end

      context 'when auth app owner is a group' do
        let(:group) { create(:group) }

        context 'when auth app owner is a root group' do
          let(:application) { create(:oauth_application, owner_id: group.id, owner_type: 'Namespace') }

          it_behaves_like 'render views'
        end

        context 'when auth app owner is a subgroup' do
          let(:subgroup) { create(:group, parent: group) }
          let(:application) { create(:oauth_application, owner_id: subgroup.id, owner_type: 'Namespace') }

          it_behaves_like 'render views'
        end
      end

      context 'when there is no owner associated' do
        let(:application) { create(:oauth_application, owner_id: nil, owner_type: nil) }

        it 'renders view' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
        end
      end
    end

    context 'without valid params' do
      it 'returns 200 code and renders error view' do
        get :new

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('doorkeeper/authorizations/error')
      end
    end

    it 'deletes session.user_return_to and redirects when skip authorization' do
      application.update!(trusted: true)
      request.session['user_return_to'] = 'http://example.com'

      subject

      expect(request.session['user_return_to']).to be_nil
      expect(response).to have_gitlab_http_status(:found)
    end
  end

  describe 'POST #create' do
    subject { post :create, params: params }

    include_examples 'OAuth Authorizations require confirmed user'
    include_examples "Implicit grant can't be used in confidential application"
  end

  describe 'DELETE #destroy' do
    subject { delete :destroy, params: params }

    include_examples 'OAuth Authorizations require confirmed user'
    include_examples "Implicit grant can't be used in confidential application"
  end

  it 'includes Two-factor enforcement concern' do
    expect(described_class.included_modules.include?(EnforcesTwoFactorAuthentication)).to eq(true)
  end
end
