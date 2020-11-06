# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImportsController do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when user is signed in' do
    context 'when bulk_import feature flag is enabled' do
      before do
        stub_feature_flags(bulk_import: true)
      end

      describe 'POST configure' do
        context 'when no params are passed in' do
          it 'clears out existing session' do
            post :configure

            expect(session[:bulk_import_gitlab_access_token]).to be_nil
            expect(session[:bulk_import_gitlab_url]).to be_nil

            expect(response).to have_gitlab_http_status(:found)
            expect(response).to redirect_to(status_import_bulk_imports_url)
          end
        end

        it 'sets the session variables' do
          token = 'token'
          url = 'https://gitlab.example'

          post :configure, params: { bulk_import_gitlab_access_token: token, bulk_import_gitlab_url: url }

          expect(session[:bulk_import_gitlab_access_token]).to eq(token)
          expect(session[:bulk_import_gitlab_url]).to eq(url)
          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(status_import_bulk_imports_url)
        end

        it 'strips access token with spaces' do
          token = 'token'

          post :configure, params: { bulk_import_gitlab_access_token: "  #{token} " }

          expect(session[:bulk_import_gitlab_access_token]).to eq(token)
          expect(controller).to redirect_to(status_import_bulk_imports_url)
        end
      end

      describe 'GET status' do
        let(:client) { BulkImports::Clients::Http.new(uri: 'http://gitlab.example', token: 'token') }

        describe 'serialized group data' do
          let(:client_response) do
            double(
              parsed_response: [
                { 'id' => 1, 'full_name' => 'group1', 'full_path' => 'full/path/group1' },
                { 'id' => 2, 'full_name' => 'group2', 'full_path' => 'full/path/group2' }
              ]
            )
          end

          before do
            allow(controller).to receive(:client).and_return(client)
            allow(client).to receive(:get).with('groups', top_level_only: true).and_return(client_response)
          end

          it 'returns serialized group data' do
            get :status, format: :json

            expect(json_response).to eq({ importable_data: client_response.parsed_response }.as_json)
          end
        end

        context 'when host url is local or not http' do
          %w[https://localhost:3000 http://192.168.0.1 ftp://testing].each do |url|
            before do
              stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

              session[:bulk_import_gitlab_access_token] = 'test'
              session[:bulk_import_gitlab_url] = url
            end

            it 'denies network request' do
              get :status

              expect(controller).to redirect_to(new_group_path)
              expect(flash[:alert]).to eq('Specified URL cannot be used: "Only allowed schemes are http, https"')
            end
          end

          context 'when local requests are allowed' do
            %w[https://localhost:3000 http://192.168.0.1].each do |url|
              before do
                stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)

                session[:bulk_import_gitlab_access_token] = 'test'
                session[:bulk_import_gitlab_url] = url
              end

              it 'allows network request' do
                get :status

                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end
        end

        context 'when connection error occurs' do
          before do
            allow(controller).to receive(:client).and_return(client)
            allow(client).to receive(:get).and_raise(BulkImports::Clients::Http::ConnectionError)
          end

          it 'returns 422' do
            get :status, format: :json

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end

          it 'clears session' do
            get :status, format: :json

            expect(session[:gitlab_url]).to be_nil
            expect(session[:gitlab_access_token]).to be_nil
          end
        end
      end

      describe 'POST create' do
        it 'executes BulkImportService' do
          expect_next_instance_of(BulkImportService) do |service|
            expect(service).to receive(:execute)
          end

          post :create

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when bulk_import feature flag is disabled' do
      before do
        stub_feature_flags(bulk_import: false)
      end

      context 'POST configure' do
        it 'returns 404' do
          post :configure

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'GET status' do
        it 'returns 404' do
          get :status

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  context 'when user is signed out' do
    before do
      sign_out(user)
    end

    context 'POST configure' do
      it 'redirects to sign in page' do
        post :configure

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'GET status' do
      it 'redirects to sign in page' do
        get :status

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
