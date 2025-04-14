# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Glql::BaseController, feature_category: :integrations do
  let(:query) { 'query GLQL { __typename }' }
  let(:query_sha) { Digest::SHA256.hexdigest(query) }

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
      it 'returns successful response and does not trigger rate limiter' do
        execute_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'data' => { '__typename' => 'Query' } })

        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to be_nil
      end

      it 'tracks SLI metrics for each successful glql query' do
        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_apdex).with({
          labels: qlql_sli_labels.merge(error_type: nil),
          success: true
        })

        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_error).with({
          labels: qlql_sli_labels.merge(error_type: nil),
          error: false
        })

        execute_request
      end

      it 'does not fail when SLIs were initialized' do
        Gitlab::Metrics::GlqlSlis.initialize_slis!

        expect { execute_request }.not_to raise_error
      end
    end

    context 'when a single ActiveRecord::QueryAborted error occurs' do
      before do
        allow(controller)
          .to receive(:execute_query)
          .once
          .and_raise(ActiveRecord::QueryCanceled)
      end

      it 're-raises ActiveRecord::QueryAborted but does not yet trigger rate limiter' do
        execute_request

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to eq "1"
      end

      it 'does not track apdex for failed queries' do
        expect(Gitlab::Metrics::GlqlSlis).not_to receive(:record_apdex)

        execute_request
      end

      it 'tracks SLI metrics for failed glql query' do
        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_error).with({
          labels: qlql_sli_labels.merge(error_type: :query_aborted),
          error: true
        })

        execute_request
      end
    end

    context 'when 2 consecutive ActiveRecord::QueryAborted errors occur' do
      it 're-raises ActiveRecord::QueryAborted and triggers rate limiter' do
        expect(controller)
          .to receive(:execute_query)
          .twice
          .and_raise(ActiveRecord::QueryCanceled)

        # Tracks SLIs for each occurrence of ActiveRecord::QueryAborted
        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_error).with({
          labels: qlql_sli_labels.merge(error_type: :query_aborted),
          error: true
        }).twice

        # 1st ActiveRecord::QueryAborted raised, error counter 1
        execute_request

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to eq "1"

        # 2nd ActiveRecord::QueryAborted raised, error counter 2
        execute_request

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_truthy
        expect(current_rate_limit_value(query_sha)).to eq "2"

        # 3rd request returns GlqlQueryLockedError right away, error counter remains the same
        execute_request

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(current_rate_limit_value(query_sha)).to eq "2"
      end
    end

    context 'when an error other than ActiveRecord::QueryAborted is raised' do
      before do
        allow(controller).to receive(:execute_query).and_raise(StandardError)
      end

      it 'handles the error but does not trigger rate limiter' do
        execute_request

        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to be_nil
      end

      it 'tracks errors for other than :query_aborted type' do
        expect(Gitlab::Metrics::GlqlSlis).to receive(:record_error).with({
          labels: qlql_sli_labels.merge(error_type: :other),
          error: true
        })

        execute_request
      end
    end

    context 'when 2 consecutive errors other than ActiveRecord::QueryAborted are raised' do
      it 'handles the error but does not trigger rate limiter' do
        expect(controller).to receive(:execute_query).twice.and_raise(StandardError)

        execute_request

        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to be_nil

        execute_request

        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to be_nil
      end
    end
  end

  describe '#append_info_to_payload' do
    let(:log_payload) { {} }
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
      RequestStore.clear!

      request.headers['Referer'] = 'path'

      allow(controller).to receive(:append_info_to_payload).and_wrap_original do |method, *|
        method.call(log_payload)
      end
    end

    it 'appends glql-related metadata for logging' do
      execute_request

      expect(controller).to have_received(:append_info_to_payload)
      expect(log_payload.dig(:metadata, :graphql)).to match_array(expected_logs)
    end
  end

  describe 'rescue_from' do
    let(:error_message) do
      'Query execution is locked due to repeated failures.'
    end

    it 'handles GlqlQueryLockedError' do
      allow(controller).to receive(:execute) do
        raise Glql::BaseController::GlqlQueryLockedError, error_message
      end

      post :execute

      expect(json_response).to include(
        'errors' => include(a_hash_including('message' => error_message))
      )
    end
  end

  def execute_request
    post :execute, params: { query: query, operationName: 'GLQL' }
  end

  def current_rate_limit_value(sha)
    # The value is nil if the key does not yet exist in Redis
    value = nil

    Gitlab::Redis::RateLimiting.with do |redis|
      redis.scan_each(match: "application_rate_limiter:glql:#{sha}*") do |key|
        value = redis.get(key)
      end
    end

    value
  end
end
