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
            expect(response).to redirect_to(status_import_bulk_import_url)
          end
        end

        it 'sets the session variables' do
          token = 'token'
          url = 'https://gitlab.example'

          post :configure, params: { bulk_import_gitlab_access_token: token, bulk_import_gitlab_url: url }

          expect(session[:bulk_import_gitlab_access_token]).to eq(token)
          expect(session[:bulk_import_gitlab_url]).to eq(url)
          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(status_import_bulk_import_url)
        end

        it 'strips access token with spaces' do
          token = 'token'

          post :configure, params: { bulk_import_gitlab_access_token: "  #{token} " }

          expect(session[:bulk_import_gitlab_access_token]).to eq(token)
          expect(controller).to redirect_to(status_import_bulk_import_url)
        end
      end

      describe 'GET status' do
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
      end
    end

    context 'when gitlab_api_imports feature flag is disabled' do
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
