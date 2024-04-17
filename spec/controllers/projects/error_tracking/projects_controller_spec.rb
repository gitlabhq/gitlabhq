# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ErrorTracking::ProjectsController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    context 'with insufficient permissions' do
      let(:user) { create(:user) }

      it 'returns 404' do
        project.add_developer(user)

        get :index, params: list_projects_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to sign-in page' do
        get :index, params: list_projects_params

        expect(response).to have_gitlab_http_status(:redirect)
      end
    end

    context 'with authorized user' do
      let(:list_projects_service) { instance_double('ErrorTracking::ListProjectsService') }
      let(:sentry_project) { build_stubbed(:error_tracking_project) }

      let(:query_params) do
        list_projects_params.slice(:api_host, :token)
      end

      before do
        allow(ErrorTracking::ListProjectsService)
          .to receive(:new).with(project, user, query_params)
          .and_return(list_projects_service)
      end

      context 'when service result is successful' do
        before do
          allow(list_projects_service).to receive(:execute)
            .and_return(status: :success, projects: [sentry_project])
        end

        it 'returns a list of projects' do
          get :index, params: list_projects_params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('error_tracking/list_projects')
          expect(json_response['projects']).to eq([sentry_project].as_json)
        end
      end

      context 'with service result is erroneous' do
        let(:error_message) { 'error message' }

        context 'without http_status' do
          before do
            allow(list_projects_service).to receive(:execute)
              .and_return(status: :error, message: error_message)
          end

          it 'returns 400 with message' do
            get :index, params: list_projects_params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq(error_message)
          end
        end

        context 'with explicit http_status' do
          let(:http_status) { :no_content }

          before do
            allow(list_projects_service).to receive(:execute).and_return(
              status: :error,
              message: error_message,
              http_status: http_status
            )
          end

          it 'returns http_status with message' do
            get :index, params: list_projects_params

            expect(response).to have_gitlab_http_status(http_status)
            expect(json_response['message']).to eq(error_message)
          end
        end
      end
    end

    private

    def list_projects_params(opts = {})
      project_params(format: :json, api_host: 'gitlab.com', token: 'token')
    end
  end

  private

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
