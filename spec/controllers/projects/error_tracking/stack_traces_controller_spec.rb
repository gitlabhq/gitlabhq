# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ErrorTracking::StackTracesController do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    let(:issue_id) { non_existing_record_id }
    let(:issue_latest_event_service) { instance_double('ErrorTracking::IssueLatestEventService') }

    subject(:get_stack_trace) do
      get :index, params: { namespace_id: project.namespace, project_id: project, issue_id: issue_id, format: :json }
    end

    before do
      allow(ErrorTracking::IssueLatestEventService)
        .to receive(:new).with(project, user, issue_id: issue_id.to_s)
        .and_return(issue_latest_event_service)

      allow(issue_latest_event_service).to receive(:execute).and_return(service_response)

      get_stack_trace
    end

    context 'when awaiting data' do
      let(:service_response) { { status: :error, http_status: :no_content } }

      it 'responds with no data' do
        expect(response).to have_gitlab_http_status(:no_content)
      end

      it_behaves_like 'sets the polling header'
    end

    context 'when service result is successful' do
      let(:service_response) { { status: :success, latest_event: error_event } }
      let(:error_event) { build_stubbed(:error_tracking_sentry_error_event) }

      it 'highlights stack trace source code' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('error_tracking/issue_stack_trace')

        expect(json_response['error']).to eq(
          Gitlab::ErrorTracking::StackTraceHighlightDecorator.decorate(error_event).as_json
        )
      end

      it_behaves_like 'sets the polling header'
    end

    context 'when service result is erroneous' do
      let(:error_message) { 'error message' }

      context 'without http_status' do
        let(:service_response) { { status: :error, message: error_message } }

        it 'responds with bad request' do
          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq(error_message)
        end
      end

      context 'with explicit http_status' do
        let(:http_status) { :no_content }
        let(:service_response) { { status: :error, message: error_message, http_status: http_status } }

        it 'responds with custom http status' do
          expect(response).to have_gitlab_http_status(http_status)
          expect(json_response['message']).to eq(error_message)
        end
      end
    end
  end
end
