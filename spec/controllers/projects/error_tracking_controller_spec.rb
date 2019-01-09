# frozen_string_literal: true

require 'rails_helper'

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

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(error_tracking: false)
        end

        it 'returns 404' do
          get :index, params: project_params

          expect(response).to have_gitlab_http_status(:not_found)
        end
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
            expect(list_issues_service).to receive(:execute)
              .and_return(status: :error, message: error_message, http_status: http_status)
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

  private

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
