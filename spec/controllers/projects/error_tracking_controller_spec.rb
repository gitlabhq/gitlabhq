# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ErrorTrackingController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  before do
    sign_in(user)
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
      let(:list_issues_service) { instance_double('ErrorTracking::ListIssuesService') }
      let(:external_url) { 'http://example.com' }

      context 'with no data' do
        let(:permitted_params) { permit_index_parameters!({}) }

        before do
          allow(ErrorTracking::ListIssuesService)
            .to receive(:new).with(project, user, permitted_params)
            .and_return(list_issues_service)

          allow(list_issues_service).to receive(:execute)
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
        let(:permitted_params) { permit_index_parameters!(search_term: search_term, sort: sort, cursor: cursor) }

        before do
          allow(ErrorTracking::ListIssuesService)
            .to receive(:new).with(project, user, permitted_params)
            .and_return(list_issues_service)
        end

        context 'when service result is successful' do
          before do
            allow(list_issues_service).to receive(:execute)
              .and_return(status: :success, issues: [error], pagination: {})
            allow(list_issues_service).to receive(:external_url)
              .and_return(external_url)

            get :index, params: params
          end

          let(:error) { build_stubbed(:error_tracking_sentry_error) }

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
          allow(ErrorTracking::ListIssuesService)
            .to receive(:new).with(project, user, permit_index_parameters!({}))
            .and_return(list_issues_service)
        end

        context 'when service result is successful' do
          before do
            allow(list_issues_service).to receive(:execute)
              .and_return(status: :success, issues: [error], pagination: {})
            allow(list_issues_service).to receive(:external_url)
              .and_return(external_url)
          end

          let(:error) { build(:error_tracking_sentry_error) }

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

        context 'when service result is erroneous' do
          let(:error_message) { 'error message' }

          context 'without http_status' do
            before do
              allow(list_issues_service).to receive(:execute)
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
              allow(list_issues_service).to receive(:execute).and_return(
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

    private

    def permit_index_parameters!(params)
      ActionController::Parameters.new(
        **params,
        tracking_event: :error_tracking_view_list
      ).permit!
    end
  end

  describe 'GET #issue_details' do
    let_it_be(:issue_id) { non_existing_record_id }

    let(:issue_details_service) { instance_double('ErrorTracking::IssueDetailsService') }

    let(:permitted_params) do
      ActionController::Parameters.new(
        issue_id: issue_id.to_s,
        tracking_event: :error_tracking_view_details
      ).permit!
    end

    before do
      allow(ErrorTracking::IssueDetailsService)
        .to receive(:new).with(project, user, permitted_params)
        .and_return(issue_details_service)
    end

    describe 'format json' do
      context 'with no data' do
        before do
          allow(issue_details_service).to receive(:execute)
            .and_return(status: :error, http_status: :no_content)
          get :details, params: issue_params(issue_id: issue_id, format: :json)
        end

        it 'returns no data' do
          expect(response).to have_gitlab_http_status(:no_content)
        end

        it_behaves_like 'sets the polling header'
      end

      context 'when service result is successful' do
        before do
          allow(issue_details_service).to receive(:execute)
            .and_return(status: :success, issue: error)

          get :details, params: issue_params(issue_id: issue_id, format: :json)
        end

        let(:error) { build_stubbed(:error_tracking_sentry_detailed_error) }

        it 'returns an error' do
          expected_error = error.as_json.except('first_release_version').merge(
            {
              'gitlab_commit' => nil,
              'gitlab_commit_path' => nil
            }
          )

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('error_tracking/issue_detailed')
          expect(json_response['error']).to eq(expected_error)
        end

        it_behaves_like 'sets the polling header'
      end

      context 'when service result is erroneous' do
        let(:error_message) { 'error message' }

        context 'without http_status' do
          before do
            allow(issue_details_service).to receive(:execute)
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
            allow(issue_details_service).to receive(:execute).and_return(
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
    let(:issue_id) { non_existing_record_id }
    let(:issue_update_service) { instance_double('ErrorTracking::IssueUpdateService') }
    let(:permitted_params) do
      ActionController::Parameters.new(
        { issue_id: issue_id.to_s, status: 'resolved' }
      ).permit!
    end

    subject(:update_issue) do
      put :update, params: issue_params(issue_id: issue_id, status: 'resolved', format: :json)
    end

    before do
      allow(ErrorTracking::IssueUpdateService)
        .to receive(:new).with(project, user, permitted_params)
        .and_return(issue_update_service)
    end

    describe 'format json' do
      context 'when user is a reporter' do
        before do
          project.add_reporter(user)
        end

        it 'returns 404 error' do
          update_issue

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when update result is successful' do
        before do
          allow(issue_update_service).to receive(:execute)
            .and_return(status: :success, updated: true, closed_issue_iid: non_existing_record_iid)

          update_issue
        end

        it 'returns a success' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('error_tracking/update_issue')
        end
      end

      context 'when update result is erroneous' do
        let(:error_message) { 'error message' }

        before do
          allow(issue_update_service).to receive(:execute)
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
