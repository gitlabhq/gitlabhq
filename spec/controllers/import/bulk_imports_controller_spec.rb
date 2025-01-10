# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImportsController, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  before do
    stub_application_setting(bulk_import_enabled: true)

    sign_in(user)

    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
  end

  context 'when user is signed in' do
    context 'when importing group and projects by direct transfer is enabled' do
      describe 'POST configure' do
        before do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
            allow(instance).to receive(:validate_instance_version!).and_return(true)
            allow(instance).to receive(:validate_import_scopes!).and_return(true)
          end
        end

        context 'when no params are passed in' do
          it 'clears out existing session' do
            post :configure

            expect(session[:bulk_import_gitlab_access_token]).to be_nil
            expect(session[:bulk_import_gitlab_url]).to be_nil

            expect(response).to have_gitlab_http_status(:found)
            expect(response).to redirect_to(status_import_bulk_imports_url)
          end
        end

        context 'when URL is invalid' do
          it 'redirects to initial import page' do
            token = 'token'
            url = 'http://192.168.0.1'

            post :configure, params: { bulk_import_gitlab_access_token: token, bulk_import_gitlab_url: url }

            expect(response).to redirect_to new_group_path(anchor: 'import-group-pane')
            expect(flash[:alert]).to include('Specified URL cannot be used')
          end
        end

        context 'when token scope is invalid' do
          before do
            allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
              allow(instance).to receive(:validate_instance_version!).and_return(true)
              allow(instance).to receive(:validate_import_scopes!).and_raise(BulkImports::Error.new('Error!'))
            end
          end

          it 'redirects to initial import page' do
            token = 'token'
            url = 'https://gitlab.example'

            post :configure, params: { bulk_import_gitlab_access_token: token, bulk_import_gitlab_url: url }

            expect(response).to redirect_to new_group_path(anchor: 'import-group-pane')
            expect(flash[:alert]).to include('Error!')
          end
        end

        context 'when instance version is incompatible' do
          before do
            allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
              allow(instance).to receive(:validate_instance_version!).and_raise(BulkImports::Error.new('Error!'))
            end
          end

          it 'redirects to initial import page' do
            token = 'token'
            url = 'https://gitlab.example'

            post :configure, params: { bulk_import_gitlab_access_token: token, bulk_import_gitlab_url: url }

            expect(response).to redirect_to new_group_path(anchor: 'import-group-pane')
            expect(flash[:alert]).to include('Error!')
          end
        end

        it 'sets the session variables' do
          token = 'invalid token'
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

        it 'passes namespace_id to status' do
          namespace_id = 5
          token = 'token'
          url = 'https://gitlab.example'

          post :configure, params: { bulk_import_gitlab_access_token: token, bulk_import_gitlab_url: url, namespace_id: namespace_id }

          expect(controller).to redirect_to(status_import_bulk_imports_url(namespace_id: namespace_id))
        end
      end

      describe 'GET status' do
        def get_status(params_override = {}, format = :json)
          params = { page: 1, per_page: 20, filter: '' }.merge(params_override)

          get :status,
            params: params,
            format: format,
            session: {
              bulk_import_gitlab_url: 'https://gitlab.example.com',
              bulk_import_gitlab_access_token: 'demo-pat'
            }
        end

        include_context 'bulk imports requests context', 'https://gitlab.example.com'

        let(:client) { BulkImports::Clients::HTTP.new(url: 'http://gitlab.example', token: 'token') }
        let(:version) { "#{BulkImport::MIN_MAJOR_VERSION}.#{BulkImport::MIN_MINOR_VERSION_FOR_PROJECT}.0" }
        let(:version_response) { double(code: 200, success?: true, parsed_response: { 'version' => version }) }

        describe 'serialized group data' do
          let(:expected_response) do
            double(
              parsed_response: [
                {
                  "full_name" => "Stub",
                  "full_path" => "stub-group",
                  "id" => 2595438,
                  "web_url" => "https://gitlab.com/groups/auto-breakfast"
                }
              ],
              headers: {
                'x-next-page' => '2',
                'x-page' => '1',
                'x-per-page' => '20',
                'x-total' => '42',
                'x-total-pages' => '2'
              }
            )
          end

          let(:source_version) do
            Gitlab::VersionInfo.new(::BulkImport::MIN_MAJOR_VERSION, ::BulkImport::MIN_MINOR_VERSION_FOR_PROJECT)
          end

          before do
            allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
              allow(instance).to receive(:instance_version).and_return(source_version)
              allow(instance).to receive(:instance_enterprise).and_return(false)
            end
          end

          it 'returns serialized group data' do
            get_status

            version_validation = {
              "features" => {
                "project_migration" => {
                  "available" => true,
                  "min_version" => BulkImport.min_gl_version_for_project_migration.to_s
                },
                "source_instance_version" => version
              }
            }

            expect(json_response).to include("importable_data" => expected_response.parsed_response, "version_validation" => hash_including(version_validation))
          end

          it 'forwards pagination headers' do
            get_status

            expect(response.headers['x-per-page']).to eq expected_response.headers['x-per-page']
            expect(response.headers['x-page']).to eq expected_response.headers['x-page']
            expect(response.headers['x-next-page']).to eq expected_response.headers['x-next-page']
            expect(response.headers['x-prev-page']).to eq expected_response.headers['x-prev-page']
            expect(response.headers['x-total']).to eq expected_response.headers['x-total']
            expect(response.headers['x-total-pages']).to eq expected_response.headers['x-total-pages']
          end

          context 'when filtering' do
            let_it_be(:filter) { 'test' }

            let(:client_params) do
              {
                top_level_only: true,
                min_access_level: Gitlab::Access::OWNER,
                search: filter
              }
            end

            it 'returns filtered result' do
              get_status(filter: filter)

              expect(json_response['importable_data'].first['full_name']).to eq('Test')
            end
          end
        end

        shared_examples 'unacceptable url' do |url, expected_error|
          before do
            stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

            session[:bulk_import_gitlab_access_token] = 'test'
            session[:bulk_import_gitlab_url] = url
          end

          it 'denies network request' do
            get :status
            expect(controller).to redirect_to(new_group_path(anchor: 'import-group-pane'))
            expect(flash[:alert]).to eq("Specified URL cannot be used: \"#{expected_error}\"")
          end
        end

        context 'when host url is local or not http' do
          include_examples 'unacceptable url', 'https://localhost:3000', "Only allowed schemes are http, https"
          include_examples 'unacceptable url', 'http://192.168.0.1', "Only allowed schemes are http, https"
          include_examples 'unacceptable url', 'ftp://testing', "Only allowed schemes are http, https"

          context 'when local requests are allowed' do
            %w[https://localhost:3000 http://192.168.0.1].each do |url|
              context "with #{url}" do
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

          context 'when namespace_id is provided' do
            let_it_be(:group) { create(:group) }

            it 'renders 404 if user does not have access to namespace' do
              get_status({ namespace_id: group.id }, :html)

              expect(response).to have_gitlab_http_status(:not_found)
            end

            it 'passes namespace to template' do
              group.add_owner(user)

              get_status({ namespace_id: group.id }, :html)

              expect(response).to have_gitlab_http_status(:ok)
              expect(assigns(:namespace)).to eq(group)
            end
          end
        end

        context 'when connection error occurs' do
          let(:source_version) do
            Gitlab::VersionInfo.new(::BulkImport::MIN_MAJOR_VERSION, ::BulkImport::MIN_MINOR_VERSION_FOR_PROJECT)
          end

          before do
            allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
              allow(instance).to receive(:instance_version).and_return(source_version)
              allow(instance).to receive(:instance_enterprise).and_return(false)
              allow(instance).to receive(:get).and_raise(BulkImports::Error)
            end
          end

          it 'returns 422' do
            get_status

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end

          it 'clears session' do
            get_status

            expect(session[:gitlab_url]).to be_nil
            expect(session[:gitlab_access_token]).to be_nil
          end
        end
      end

      describe 'GET /history' do
        subject(:request) { get :history }

        it 'responds with a 200 and shows the template', :aggregate_failures do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:history)
        end
      end

      describe 'GET /:id/history' do
        let_it_be(:bulk_import) { create(:bulk_import, user: user) }

        subject(:request) { get :history, params: { id: id } }

        describe 'when bulk_import does not exist' do
          let(:id) { 18231 }

          it 'responds with a 404' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        describe 'when bulk_import exists' do
          let(:id) { bulk_import.id }

          it 'responds with a 200 and shows the template', :aggregate_failures do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:history)
          end
        end
      end

      describe 'GET failures' do
        let_it_be(:bulk_import) { create(:bulk_import, user: user) }
        let_it_be(:bulk_import_entity) { create(:bulk_import_entity, bulk_import: bulk_import) }
        let(:id) { bulk_import.id }
        let(:entity_id) { bulk_import_entity.id }

        subject(:request) { get :failures, params: { id: id, entity_id: entity_id } }

        describe 'when bulk_import does not exist' do
          let(:id) { 18231 }

          it 'responds with a 404' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        describe 'when bulk_import_entity does not exist' do
          let(:entity_id) { 136485 }

          it 'responds with a 404' do
            request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        describe 'when both bulk_import and bulk_import_entity exist' do
          it 'responds with a 200 and shows the template', :aggregate_failures do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to render_template(:failures)
          end
        end
      end

      describe 'GET realtime_changes' do
        let_it_be(:bulk_import) { create(:bulk_import, :created, user: user) }

        it 'returns bulk imports created by current user' do
          get :realtime_changes

          expect(json_response).to match_array([{ 'id' => bulk_import.id, 'status_name' => bulk_import.status_name.to_s, 'has_failures' => false }])
        end

        it 'sets a Poll-Interval header' do
          get :realtime_changes

          expect(response.headers['Poll-Interval']).to eq(Import::BulkImportsController::POLLING_INTERVAL.to_s)
        end
      end

      describe 'POST create' do
        let(:instance_url) { "http://fake-instance" }
        let(:bulk_import) { create(:bulk_import) }
        let(:pat) { "fake-pat" }
        let(:bulk_import_params) do
          [{ "source_type" => "group_entity",
             "source_full_path" => "full_path",
             "destination_slug" => "destination_name",
             "destination_namespace" => "root" },
           { "source_type" => "group_entity",
             "source_full_path" => "full_path",
             "destination_slug" => "destination_name",
             "destination_namespace" => "invalid-namespace" }]
        end

        before do
          session[:bulk_import_gitlab_access_token] = pat
          session[:bulk_import_gitlab_url] = instance_url
        end

        it 'executes BulkImports::CreateService' do
          error_response = ServiceResponse.error(message: 'Record invalid', http_status: :unprocessable_entity)

          expect_next_instance_of(
            ::BulkImports::CreateService, user, bulk_import_params[0], { url: instance_url, access_token: pat },
            fallback_organization: Organizations::Organization.default_organization
          ) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.success(payload: bulk_import))
          end

          expect_next_instance_of(
            ::BulkImports::CreateService, user, bulk_import_params[1], { url: instance_url, access_token: pat },
            fallback_organization: Organizations::Organization.default_organization
          ) do |service|
            allow(service).to receive(:execute).and_return(error_response)
          end

          post :create, params: { bulk_import: bulk_import_params }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to eq([{ "success" => true, "id" => bulk_import.id, "message" => nil },
                                       { "success" => false, "id" => nil, "message" => "Record invalid" }])
        end

        context 'when entity destination_name is specified' do
          let(:bulk_import_params) do
            [
              {
                "source_type" => "group_entity",
                "source_full_path" => "full_path",
                "destination_name" => "destination_name",
                "destination_namespace" => "root"
              }
            ]
          end

          it 'replaces destination_name with destination_slug and executes BulkImports::CreateService' do
            entity = {
              "source_type" => "group_entity",
              "source_full_path" => "full_path",
              "destination_slug" => "destination_name",
              "destination_namespace" => "root"
            }

            expect_next_instance_of(
              ::BulkImports::CreateService, user, entity, { url: instance_url, access_token: pat },
              fallback_organization: Organizations::Organization.default_organization
            ) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.success(payload: bulk_import))
            end

            post :create, params: { bulk_import: bulk_import_params }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to match_array([{ "success" => true, "id" => bulk_import.id, "message" => nil }])
          end
        end

        context 'when source type is project' do
          let(:bulk_import_params) do
            [{ "source_type" => "project_entity",
               "source_full_path" => "full_path",
               "destination_slug" => "destination_name",
               "destination_namespace" => "root" }]
          end

          it 'returns 422' do
            post :create, params: { bulk_import: bulk_import_params }

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end
        end

        context 'when request exceeds rate limits' do
          it 'prevents user from starting a new migration' do
            allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

            post :create, params: { bulk_import: {} }

            request

            expect(response).to have_gitlab_http_status(:too_many_requests)
          end
        end

        context 'when current organization is set', :with_current_organization do
          it 'passes the current organization to the ::BulkImports::CreateService' do
            expect_next_instance_of(
              ::BulkImports::CreateService, anything, anything, anything, fallback_organization: current_organization
            ) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.success(payload: bulk_import))
            end.twice

            post :create, params: { bulk_import: bulk_import_params }
          end
        end
      end
    end

    context 'when importing groups and projects by direct transfer is disabled' do
      before do
        stub_application_setting(bulk_import_enabled: false)

        allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
          allow(instance).to receive(:validate_instance_version!).and_return(true)
          allow(instance).to receive(:validate_import_scopes!).and_return(true)
        end
      end

      context 'POST configure' do
        it 'returns 404' do
          post :configure, params: {
            bulk_import_gitlab_access_token: 'token', bulk_import_gitlab_url: 'https://gitlab.example'
          }

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
