# frozen_string_literal: true

require 'spec_helper'

describe Projects::ErrorTrackingController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

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
      let(:list_issues_service) { spy(:list_issues_service) }
      let(:external_url) { 'http://example.com' }

      context 'no data' do
        let(:permitted_params) do
          ActionController::Parameters.new({}).permit!
        end

        before do
          expect(ErrorTracking::ListIssuesService)
            .to receive(:new).with(project, user, permitted_params)
            .and_return(list_issues_service)

          expect(list_issues_service).to receive(:execute)
            .and_return(status: :error, http_status: :no_content)
        end

        it 'returns no data' do
          get :index, params: project_params(format: :json)

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'with extra params' do
        let(:cursor) { '1572959139000:0:0' }
        let(:search_term) { 'something' }
        let(:sort) { 'last_seen' }
        let(:params) { project_params(format: :json, search_term: search_term, sort: sort, cursor: cursor) }
        let(:permitted_params) do
          ActionController::Parameters.new(search_term: search_term, sort: sort, cursor: cursor).permit!
        end

        before do
          expect(ErrorTracking::ListIssuesService)
            .to receive(:new).with(project, user, permitted_params)
            .and_return(list_issues_service)
        end

        context 'service result is successful' do
          before do
            expect(list_issues_service).to receive(:execute)
              .and_return(status: :success, issues: [error], pagination: {})
            expect(list_issues_service).to receive(:external_url)
              .and_return(external_url)

            get :index, params: params
          end

          let(:error) { build(:error_tracking_error) }

          it 'returns a list of errors' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('error_tracking/index')
            expect(json_response).to eq(
              'errors' => [error].as_json,
              'pagination' => {},
              'external_url' => external_url
            )
          end

          it_behaves_like 'sets the polling header'
        end
      end

      context 'without extra params' do
        before do
          expect(ErrorTracking::ListIssuesService)
            .to receive(:new).with(project, user, {})
            .and_return(list_issues_service)
        end

        context 'service result is successful' do
          before do
            expect(list_issues_service).to receive(:execute)
              .and_return(status: :success, issues: [error], pagination: {})
            expect(list_issues_service).to receive(:external_url)
              .and_return(external_url)
          end

          let(:error) { build(:error_tracking_error) }

          it 'returns a list of errors' do
            get :index, params: project_params(format: :json)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('error_tracking/index')
            expect(json_response).to eq(
              'errors' => [error].as_json,
              'pagination' => {},
              'external_url' => external_url
            )
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
  end

  describe 'GET #issue_details' do
    let_it_be(:issue_id) { 1234 }

    let(:issue_details_service) { spy(:issue_details_service) }

    let(:permitted_params) do
      ActionController::Parameters.new(
        { issue_id: issue_id.to_s }
      ).permit!
    end

    before do
      expect(ErrorTracking::IssueDetailsService)
        .to receive(:new).with(project, user, permitted_params)
        .and_return(issue_details_service)
    end

    describe 'format json' do
      context 'no data' do
        before do
          expect(issue_details_service).to receive(:execute)
            .and_return(status: :error, http_status: :no_content)
          get :details, params: issue_params(issue_id: issue_id, format: :json)
        end

        it 'returns no data' do
          expect(response).to have_gitlab_http_status(:no_content)
        end

        it_behaves_like 'sets the polling header'
      end

      context 'service result is successful' do
        before do
          expect(issue_details_service).to receive(:execute)
            .and_return(status: :success, issue: error)

          get :details, params: issue_params(issue_id: issue_id, format: :json)
        end

        let(:error) { build(:detailed_error_tracking_error) }

        it 'returns an error' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('error_tracking/issue_detailed')
          expect(json_response['error']).to eq(error.as_json)
        end

        it_behaves_like 'sets the polling header'
      end

      context 'service result is erroneous' do
        let(:error_message) { 'error message' }

        context 'without http_status' do
          before do
            expect(issue_details_service).to receive(:execute)
              .and_return(status: :error, message: error_message)
          end

          it 'returns 400 with message' do
            get :details, params: issue_params(issue_id: issue_id, format: :json)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq(error_message)
          end
        end

        context 'with explicit http_status' do
          let(:http_status) { :no_content }

          before do
            expect(issue_details_service).to receive(:execute).and_return(
              status: :error,
              message: error_message,
              http_status: http_status
            )
          end

          it 'returns http_status with message' do
            get :details, params: issue_params(issue_id: issue_id, format: :json)

            expect(response).to have_gitlab_http_status(http_status)
            expect(json_response['message']).to eq(error_message)
          end
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:issue_id) { 1234 }
    let(:issue_update_service) { spy(:issue_update_service) }
    let(:permitted_params) do
      ActionController::Parameters.new(
        { issue_id: issue_id.to_s, status: 'resolved' }
      ).permit!
    end

    subject(:update_issue) do
      put :update, params: issue_params(issue_id: issue_id, status: 'resolved', format: :json)
    end

    before do
      expect(ErrorTracking::IssueUpdateService)
        .to receive(:new).with(project, user, permitted_params)
        .and_return(issue_update_service)
    end

    describe 'format json' do
      context 'update result is successful' do
        before do
          expect(issue_update_service).to receive(:execute)
            .and_return(status: :success, updated: true)

          update_issue
        end

        it 'returns a success' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('error_tracking/update_issue')
        end
      end

      context 'update result is erroneous' do
        let(:error_message) { 'error message' }

        before do
          expect(issue_update_service).to receive(:execute)
            .and_return(status: :error, message: error_message)

          update_issue
        end

        it 'returns 400 with message' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq(error_message)
        end
      end
    end
  end

  private

  def issue_params(opts = {})
    project_params.reverse_merge(opts)
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
