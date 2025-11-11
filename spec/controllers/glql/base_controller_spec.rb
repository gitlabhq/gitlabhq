# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Glql::BaseController, feature_category: :integrations do
  let(:query) { 'query GLQL { __typename }' }
  let(:query_sha) { Digest::SHA256.hexdigest(query) }
  let(:rate_limit_message) do
    'Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope.'
  end

  # Shared helper to mock QueryService with different response scenarios
  def mock_query_service(response_type = :success, custom_options = {})
    default_responses = {
      success: {
        data: { '__typename' => 'Query' },
        errors: nil,
        complexity_score: 1,
        duration_s: 0.1,
        timeout_occurred: false,
        rate_limited: false
      },
      timeout: {
        data: nil,
        errors: [{ message: 'Query timed out' }],
        complexity_score: nil,
        duration_s: 0.1,
        timeout_occurred: true,
        rate_limited: false
      },
      rate_limited: {
        data: nil,
        errors: [{ message: rate_limit_message }],
        complexity_score: nil,
        duration_s: 0.1,
        timeout_occurred: false,
        rate_limited: true
      },
      exception: {
        data: nil,
        errors: [{ message: 'Test error' }],
        complexity_score: nil,
        duration_s: 0.1,
        timeout_occurred: false,
        rate_limited: false,
        exception: StandardError.new('Test error')
      },
      failed: {
        data: nil,
        errors: [{ message: 'Query failed' }],
        complexity_score: nil,
        duration_s: 0.1,
        timeout_occurred: false,
        rate_limited: false,
        exception: StandardError.new('Query failed')
      }
    }

    response = default_responses[response_type].merge(custom_options)

    allow_next_instance_of(::Integrations::Glql::QueryService) do |instance|
      allow(instance).to receive(:execute).and_return(response)
    end
  end

  describe 'POST #execute' do
    let(:user) { create(:user, last_activity_on: 2.days.ago.to_date) }
    let(:endpoint_id) { 'Glql::BaseController#execute' }
    let(:qlql_sli_labels) do
      { endpoint_id: endpoint_id, feature_category: 'not_owned', query_urgency: :low }
    end

    before do
      sign_in(user)

      # The application context is set by the ActionControllerStaticContext middleware
      # in lib/gitlab/middleware/action_controller_static_context.rb.
      # However, this middleware is not called in our controller specs,
      # so we explicitly set the caller id here; otherwise, it returns nil.
      Gitlab::ApplicationContext.push({ caller_id: endpoint_id })

      # Gitlab::ApplicationRateLimiter stores failed attempts in Redis to track the state
      # The format is the following 'application_rate_limiter:glql:<SHA>:<TIMESTAMP>'
      # Let's clean up Redis to ensure a clean state
      Gitlab::Redis::RateLimiting.with(&:flushdb)
    end

    context 'when a GLQL query executes successfully' do
      before do
        mock_query_service(:success)
      end

      it 'returns successful response and does not trigger rate limiter' do
        execute_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'data' => { '__typename' => 'Query' } })
        # Rate limiting is handled by QueryService, not tested here
      end

      it 'does not fail when SLIs were initialized' do
        Gitlab::Metrics::GlqlSlis.initialize_slis!

        expect { execute_request }.not_to raise_error
      end
    end

    context 'when a single ActiveRecord::QueryAborted error occurs' do
      before do
        mock_query_service(:timeout)
      end

      it 're-raises ActiveRecord::QueryAborted and returns service unavailable' do
        execute_request

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(json_response['errors']).to include(a_hash_including('message' => 'Query timed out'))
        # Rate limiting is handled by QueryService, not tested here
      end
    end

    context 'when rate limiting is triggered' do
      before do
        mock_query_service(:rate_limited)
      end

      it 'handles GlqlQueryLockedError and returns forbidden status' do
        execute_request

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['errors']).to include(a_hash_including('message' => rate_limit_message))
        # Rate limiting is handled by QueryService, not tested here
      end
    end

    context 'when an error other than ActiveRecord::QueryAborted is raised' do
      before do
        mock_query_service(:exception)
      end

      it 'handles the error and returns internal server error' do
        execute_request

        expect(response).to have_gitlab_http_status(:internal_server_error)
        expect(json_response['errors']).to include(a_hash_including('message' => 'Internal server error: Test error'))
        # Rate limiting is handled by QueryService, not tested here
      end
    end

    context 'when load balancing enabled', :db_load_balancing do
      before do
        mock_query_service(:success)
      end

      it 'uses QueryService which handles load balancing' do
        expect_next_instance_of(::Integrations::Glql::QueryService) do |instance|
          expect(instance).to receive(:execute).with(
            query: query,
            variables: {},
            context: { is_sessionless_user: false }
          )
        end

        execute_request
      end
    end
  end

  describe '#append_info_to_payload' do
    let(:log_payload) { {} }

    before do
      RequestStore.clear!

      request.headers['Referer'] = 'path'

      allow(controller).to receive(:append_info_to_payload).and_wrap_original do |method, *|
        method.call(log_payload)
      end
    end

    context 'when GraphQL execution succeeds' do
      let(:expected_logs) do
        [
          {
            operation_name: 'GLQL',
            complexity: 1,
            depth: 1,
            used_deprecated_arguments: [],
            used_deprecated_fields: [],
            used_fields: ['Query.__typename'],
            variables: '{}',
            glql_referer: 'path',
            glql_query_sha: query_sha
          }
        ]
      end

      before do
        # Mock the GraphQL logs that would be created by the QueryService
        RequestStore.store[:graphql_logs] = [
          {
            operation_name: 'GLQL',
            complexity: 1,
            depth: 1,
            used_deprecated_arguments: [],
            used_deprecated_fields: [],
            used_fields: ['Query.__typename'],
            variables: '{}',
            glql_referer: 'path',
            glql_query_sha: query_sha
          }
        ]
      end

      it 'appends glql-related metadata for logging' do
        execute_request

        expect(controller).to have_received(:append_info_to_payload)
        expect(log_payload.dig(:metadata, :graphql)).to include(
          hash_including(
            operation_name: 'GLQL',
            complexity: 1,
            depth: 1,
            used_deprecated_arguments: [],
            used_deprecated_fields: [],
            used_fields: ['Query.__typename'],
            variables: '{}',
            glql_referer: 'path',
            glql_query_sha: query_sha
          )
        )
      end
    end

    context 'when GraphQL execution fails' do
      let(:expected_error_logs) do
        [
          {
            glql_referer: 'path',
            glql_query_sha: query_sha
          }
        ]
      end

      before do
        # Mock the GraphQL logs that would be created by the QueryService for failed queries
        RequestStore.store[:graphql_logs] = [
          {
            glql_referer: 'path',
            glql_query_sha: query_sha
          }
        ]
      end

      it 'still appends glql-related metadata for logging' do
        mock_query_service(:failed)

        execute_request

        expect(controller).to have_received(:append_info_to_payload)
        expect(log_payload.dig(:metadata, :graphql)).to match_array(expected_error_logs)
      end
    end
  end

  describe 'rescue_from' do
    let(:error_message) do
      'Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope.'
    end

    it 'handles GlqlQueryLockedError' do
      mock_query_service(:rate_limited)

      execute_request

      expect(json_response).to include(
        'errors' => include(a_hash_including('message' => error_message))
      )
    end
  end

  describe 'set_namespace_context' do
    before do
      mock_query_service(:success)
    end

    context 'when the `project` param is provided' do
      let_it_be(:project) { create(:project) }

      before do
        execute_request({ project: project.full_path })
      end

      it 'sets @project variable and has the meta.project updated' do
        expect(Gitlab::ApplicationContext.current['meta.project']).to eq(project.full_path)
      end

      it 'has the meta.root_namespace updated based on @project' do
        expect(Gitlab::ApplicationContext.current['meta.root_namespace'])
          .to eq(project.full_path_components.first)
      end
    end

    context 'when the `group` param is provided' do
      let_it_be(:group) { create(:group) }

      it 'has the meta.root_namespace updated based on @group' do
        execute_request({ group: group.full_path })

        expect(Gitlab::ApplicationContext.current['meta.root_namespace'])
          .to eq(group.full_path_components.first)
      end
    end

    context 'when none of `group` and `project` params are provided' do
      it 'does not set the application context meta fields' do
        execute_request

        expect(Gitlab::ApplicationContext.current['meta.root_namespace']).to be_nil
        expect(Gitlab::ApplicationContext.current['meta.project']).to be_nil
      end
    end
  end

  describe 'QueryService integration' do
    let(:user) { create(:user, last_activity_on: 2.days.ago.to_date) }

    before do
      sign_in(user)
      Current.organization = create(:organization)
    end

    it 'creates QueryService with correct parameters' do
      expect(::Integrations::Glql::QueryService).to receive(:new) do |args|
        expect(args[:current_user]).to eq(user)
        expect(args[:original_query]).to eq(query)
        expect(args[:request]).to eq(request)
        expect(args[:current_organization]).to eq(Current.organization)
      end.and_call_original

      mock_query_service(:success)

      execute_request
    end

    it 'calls QueryService#execute with correct parameters' do
      expect_next_instance_of(::Integrations::Glql::QueryService) do |instance|
        expect(instance).to receive(:execute).with(
          query: query,
          variables: {},
          context: { is_sessionless_user: false }
        )
      end

      execute_request
    end
  end

  def execute_request(extra_params = {})
    post :execute, params: { query: query, operationName: 'GLQL' }.merge(extra_params)
  end
end
