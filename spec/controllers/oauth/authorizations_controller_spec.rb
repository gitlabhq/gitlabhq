# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::AuthorizationsController do
  let(:user) { create(:user) }
  let(:application_scopes) { 'api read_user' }
  let(:confidential) { true }

  let!(:application) do
    create(
      :oauth_application,
      scopes: application_scopes,
      redirect_uri: 'http://example.com',
      confidential: confidential
    )
  end

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
      let(:user) { create(:user, :unconfirmed) }

      it 'returns 200 and renders error view' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('doorkeeper/authorizations/error')
      end
    end
  end

  describe 'GET #new' do
    subject { get :new, params: params }

    context 'when the user is confirmed' do
      context 'when there is already an access token for the application with a matching scope' do
        before do
          scopes = Doorkeeper::OAuth::Scopes.from_string('api')

          allow(Doorkeeper.configuration).to receive(:scopes).and_return(scopes)

          create(:oauth_access_token, application: application, resource_owner_id: user.id, scopes: scopes)
        end

        context 'when application is confidential' do
          let(:confidential) { true }

          it 'authorizes the request and shows the user a page that redirects' do
            subject

            expect(request.session['user_return_to']).to be_nil
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template('doorkeeper/authorizations/redirect')
          end
        end

        context 'when application is not confidential' do
          let(:confidential) { false }

          it 'returns 200 code and renders view' do
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

      context 'with valid params' do
        render_views

        it 'returns 200 code and renders view' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
        end

        it 'deletes session.user_return_to and redirects when skip authorization' do
          application.update!(trusted: true)
          request.session['user_return_to'] = 'http://example.com'

          subject

          expect(request.session['user_return_to']).to be_nil
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/redirect')
        end

        context 'with gl_auth_type=login' do
          let(:minimal_scope) { Gitlab::Auth::READ_USER_SCOPE.to_s }

          before do
            params[:gl_auth_type] = 'login'
          end

          shared_examples 'downgrades scopes' do
            it 'downgrades the scopes' do
              subject

              pre_auth = controller.send(:pre_auth)

              expect(pre_auth.scopes).to contain_exactly(minimal_scope)
              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to render_template('doorkeeper/authorizations/new')
              # See: config/locales/doorkeeper.en.yml
              expect(response.body).to include("Read the authenticated user&#39;s personal information")
              expect(response.body).not_to include("Access the authenticated user&#39;s API")
            end
          end

          shared_examples 'adds read_user scope' do
            it 'modifies the client.application.scopes' do
              expect { subject }
                .to change { application.reload.scopes }.to include(minimal_scope)
            end

            it 'does not remove pre-existing scopes' do
              subject

              expect(application.scopes).to include(*application_scopes.split(/ /))
            end
          end

          context 'the application has all scopes' do
            let(:application_scopes) { 'api read_api read_user' }

            include_examples 'downgrades scopes'
          end

          context 'the application has api and read_user scopes' do
            let(:application_scopes) { 'api read_user' }

            include_examples 'downgrades scopes'
          end

          context 'the application has read_api and read_user scopes' do
            let(:application_scopes) { 'read_api read_user' }

            include_examples 'downgrades scopes'
          end

          context 'the application has only api scopes' do
            let(:application_scopes) { 'api' }

            include_examples 'downgrades scopes'
            include_examples 'adds read_user scope'
          end

          context 'the application has only read_api scopes' do
            let(:application_scopes) { 'read_api' }

            include_examples 'downgrades scopes'
            include_examples 'adds read_user scope'
          end

          context 'the application has scopes we do not handle' do
            let(:application_scopes) { Gitlab::Auth::PROFILE_SCOPE.to_s }

            before do
              params[:scope] = application_scopes
            end

            it 'does not modify the scopes' do
              subject

              pre_auth = controller.send(:pre_auth)

              expect(pre_auth.scopes).to contain_exactly(application_scopes)
              expect(response).to have_gitlab_http_status(:ok)
              expect(response).to render_template('doorkeeper/authorizations/new')
            end
          end
        end
      end
    end

    context 'when the user is admin' do
      context 'when disable_admin_oauth_scopes is set' do
        before do
          stub_application_setting(disable_admin_oauth_scopes: true)
          scopes = Doorkeeper::OAuth::Scopes.from_string('api')

          allow(Doorkeeper.configuration).to receive(:scopes).and_return(scopes)
        end

        let(:user) { create(:user, :admin) }

        it 'returns 200 and renders forbidden view' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/forbidden')
        end
      end

      context 'when disable_admin_oauth_scopes is set and the application is trusted' do
        before do
          stub_application_setting(disable_admin_oauth_scopes: true)

          application.update!(trusted: true)
        end

        let(:application_scopes) { 'api' }
        let(:user) { create(:user, :admin) }

        it 'returns 200 and renders redirect view' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/redirect')
        end
      end

      context 'when disable_admin_oauth_scopes is disabled' do
        before do
          stub_application_setting(disable_admin_oauth_scopes: false)
        end

        let(:application_scopes) { 'api' }
        let(:user) { create(:user, :admin) }

        it 'returns 200 and renders new view' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
        end
      end
    end

    context 'when the user is not admin' do
      context 'when disable_admin_oauth_scopes is enabled' do
        before do
          stub_application_setting(disable_admin_oauth_scopes: true)
        end

        it 'returns 200 and renders new view' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template('doorkeeper/authorizations/new')
        end
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: params }

    include_examples 'OAuth Authorizations require confirmed user'
  end

  describe 'DELETE #destroy' do
    subject { delete :destroy, params: params }

    include_examples 'OAuth Authorizations require confirmed user'
  end

  it 'includes Two-factor enforcement concern' do
    expect(described_class.included_modules.include?(EnforcesTwoFactorAuthentication)).to eq(true)
  end

  describe 'Gon variables' do
    it 'adds Gon variables' do
      expect(controller).to receive(:add_gon_variables)
      get :new, params: params
    end

    it 'includes GonHelper module' do
      expect(controller).to be_a(Gitlab::GonHelper)
    end
  end
end
