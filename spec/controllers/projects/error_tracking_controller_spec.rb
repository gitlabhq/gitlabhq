# frozen_string_literal: true

require 'spec_helper'

describe Projects::ErrorTrackingController do
  set(:project) { create(:project) }
  set(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET #index' do
    describe 'html' do
      it 'renders index with 200 status code' do
        get :index, params: project_params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:index)
      end

      context 'with insufficient permissions' do
        before do
          project.add_guest(user)
        end

        it 'returns 404' do
          get :index, params: project_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with an anonymous user' do
        before do
          sign_out(user)
        end

        it 'redirects to sign-in page' do
          get :index, params: project_params

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    describe 'format json' do
      shared_examples 'no data' do
        it 'returns no data' do
          get :index, params: project_params(format: :json)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('error_tracking/index')
          expect(json_response['external_url']).to be_nil
          expect(json_response['errors']).to eq([])
        end
      end

      let(:list_issues_service) { spy(:list_issues_service) }
      let(:external_url) { 'http://example.com' }

      before do
        expect(ErrorTracking::ListIssuesService)
          .to receive(:new).with(project, user)
          .and_return(list_issues_service)
      end

      context 'service result is successful' do
        before do
          expect(list_issues_service).to receive(:execute)
            .and_return(status: :success, issues: [error])
          expect(list_issues_service).to receive(:external_url)
            .and_return(external_url)
        end

        let(:error) { build(:error_tracking_error) }

        it 'returns a list of errors' do
          get :index, params: project_params(format: :json)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('error_tracking/index')
          expect(json_response['external_url']).to eq(external_url)
          expect(json_response['errors']).to eq([error].as_json)
        end
      end

      context 'service result is erroneous' do
        let(:error_message) { 'error message' }

        context 'without http_status' do
          before do
            expect(list_issues_service).to receive(:execute)
              .and_return(status: :error, message: error_message)
          end

          it 'returns 400 with message' do
            get :index, params: project_params(format: :json)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq(error_message)
          end
        end

        context 'with explicit http_status' do
          let(:http_status) { :no_content }

          before do
            expect(list_issues_service).to receive(:execute).and_return(
              status: :error,
              message: error_message,
              http_status: http_status
            )
          end

          it 'returns http_status with message' do
            get :index, params: project_params(format: :json)

            expect(response).to have_gitlab_http_status(http_status)
            expect(json_response['message']).to eq(error_message)
          end
        end
      end
    end
  end

  describe 'POST #list_projects' do
    context 'with insufficient permissions' do
      before do
        project.add_guest(user)
      end

      it 'returns 404' do
        post :list_projects, params: list_projects_params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to sign-in page' do
        post :list_projects, params: list_projects_params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with authorized user' do
      let(:list_projects_service) { spy(:list_projects_service) }
      let(:sentry_project) { build(:error_tracking_project) }

      let(:permitted_params) do
        ActionController::Parameters.new(
          list_projects_params[:error_tracking_setting]
        ).permit!
      end

      before do
        allow(ErrorTracking::ListProjectsService)
          .to receive(:new).with(project, user, permitted_params)
          .and_return(list_projects_service)
      end

      context 'service result is successful' do
        before do
          expect(list_projects_service).to receive(:execute)
            .and_return(status: :success, projects: [sentry_project])
        end

        it 'returns a list of projects' do
          post :list_projects, params: list_projects_params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('error_tracking/list_projects')
          expect(json_response['projects']).to eq([sentry_project].as_json)
        end
      end

      context 'service result is erroneous' do
        let(:error_message) { 'error message' }

        context 'without http_status' do
          before do
            expect(list_projects_service).to receive(:execute)
              .and_return(status: :error, message: error_message)
          end

          it 'returns 400 with message' do
            get :list_projects, params: list_projects_params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq(error_message)
          end
        end

        context 'with explicit http_status' do
          let(:http_status) { :no_content }

          before do
            expect(list_projects_service).to receive(:execute).and_return(
              status: :error,
              message: error_message,
              http_status: http_status
            )
          end

          it 'returns http_status with message' do
            get :list_projects, params: list_projects_params

            expect(response).to have_gitlab_http_status(http_status)
            expect(json_response['message']).to eq(error_message)
          end
        end
      end
    end

    private

    def list_projects_params(opts = {})
      project_params(
        format: :json,
        error_tracking_setting: {
          api_host: 'gitlab.com',
          token: 'token'
        }
      )
    end
  end

  private

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
