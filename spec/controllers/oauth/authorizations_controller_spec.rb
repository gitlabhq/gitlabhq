# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::AuthorizationsController, :with_current_organization, feature_category: :system_access do
  let(:user) { create(:user, organizations: [current_organization]) }
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

  shared_examples 'RequestPayloadLogger information appended' do
    it 'logs custom information in the payload' do
      expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
        method.call(payload)

        expect(payload[:remote_ip]).to be_present
        expect(payload[:username]).to eq(user.username)
        expect(payload[:user_id]).to be_present
        expect(payload[:ua]).to be_present
      end

      subject
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

        it "creates access grant on the Current.organization" do
          expect { subject }.to change { OauthAccessGrant.where(organization: current_organization).count }
        end

        context 'when showing applications as provided' do
          let!(:application) do
            create(
              :oauth_application,
              owner_id: nil,
              owner_type: nil,
              scopes: application_scopes,
              redirect_uri: 'http://example.com',
              confidential: confidential
            )
          end

          context 'when on GitLab.com' do
            before do
              allow(Gitlab).to receive(:com?).and_return(true)
            end

            it 'displays the provided application message' do
              subject
              expect(response.body).to have_css('p.gl-text-success', text: 'This application is provided by GitLab.')
              expect(response.body).to have_css('[data-testid="tanuki-verified-icon"]')
            end

            context 'when redirect uri has www pattern' do
              before do
                application.redirect_uri = "http://www.examplewww.com"
                application.save!
              end

              it 'substitutes pattern correctly on display' do
                subject
                expect(response.body).to have_css('p', text: "You will be redirected to examplewww.com")
              end
            end
          end

          context 'when not on GitLab.com' do
            before do
              allow(Gitlab).to receive(:com?).and_return(false)
            end

            it 'displays the warning message' do
              subject
              expect(response.body).to have_css(
                'p.gl-text-warning', text: "Make sure you trust #{application.name} before authorizing.")
              expect(response.body).to have_css('[data-testid="warning-solid-icon"]')
            end
          end
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
              expect(response.body).to include("Read your personal information")
              expect(response.body).not_to include("Access the API on your behalf")
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
      let_it_be(:user) { create(:user, :admin, organizations: [current_organization]) }

      context 'when disable_admin_oauth_scopes is set' do
        before do
          stub_application_setting(disable_admin_oauth_scopes: true)
          scopes = Doorkeeper::OAuth::Scopes.from_string('api')

          allow(Doorkeeper.configuration).to receive(:scopes).and_return(scopes)
        end

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

    it_behaves_like "RequestPayloadLogger information appended"
  end

  describe 'POST #create' do
    subject { post :create, params: params }

    it_behaves_like "RequestPayloadLogger information appended"

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

  describe '#audit_oauth_authorization' do
    let(:pre_auth) { instance_double(Doorkeeper::OAuth::PreAuthorization) }
    let(:client) { instance_double(Doorkeeper::OAuth::Client) }

    before do
      allow(controller).to receive(:pre_auth).and_return(pre_auth)
      allow(pre_auth).to receive(:client).and_return(client)
      allow(client).to receive(:application).and_return(application)
    end

    context 'when response is successful' do
      before do
        allow(controller).to receive(:performed?).and_return(true)
        allow(controller).to receive_message_chain(:response, :successful?).and_return(true)
      end

      it 'creates an audit event' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(
          name: 'user_authorized_oauth_application',
          author: user,
          scope: user,
          target: application,
          message: 'User authorized an OAuth application.',
          additional_details: {
            application_name: application.name,
            application_id: application.id,
            scopes: application.scopes.to_a
          },
          ip_address: request.remote_ip
        )

        controller.send(:audit_oauth_authorization)
      end
    end

    context 'when response is a redirect' do
      before do
        allow(controller).to receive(:performed?).and_return(true)
        allow(controller).to receive_message_chain(:response, :successful?).and_return(false)
        allow(controller).to receive_message_chain(:response, :redirect?).and_return(true)
      end

      it 'creates an audit event' do
        expect(Gitlab::Audit::Auditor).to receive(:audit)

        controller.send(:audit_oauth_authorization)
      end
    end

    context 'when response is not performed' do
      before do
        allow(controller).to receive(:performed?).and_return(false)
      end

      it 'does not create an audit event' do
        expect(Gitlab::Audit::Auditor).not_to receive(:audit)

        controller.send(:audit_oauth_authorization)
      end
    end

    context 'when response is neither successful nor redirect' do
      before do
        allow(controller).to receive(:performed?).and_return(true)
        allow(controller).to receive_message_chain(:response, :successful?).and_return(false)
        allow(controller).to receive_message_chain(:response, :redirect?).and_return(false)
      end

      it 'does not create an audit event' do
        expect(Gitlab::Audit::Auditor).not_to receive(:audit)

        controller.send(:audit_oauth_authorization)
      end
    end
  end
end
