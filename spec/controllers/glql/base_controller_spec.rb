# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Glql::BaseController, feature_category: :integrations do
  describe 'POST #execute' do
    let(:user) { create(:user, last_activity_on: 2.days.ago.to_date) }
    let(:query) { 'query GLQL { __typename }' }
    let(:operation_name) { 'GLQL' }
    let(:query_sha) { Digest::SHA256.hexdigest(query) }

    before do
      sign_in(user)

      # Gitlab::ApplicationRateLimiter stores failed attempts in Redis to track the state
      # The format is the following 'application_rate_limiter:glql:<SHA>:<TIMESTAMP>'
      # Let's clean up Redis to ensure a clean state
      Gitlab::Redis::RateLimiting.with(&:flushdb)
    end

    context 'when a GLQL query executes successfully' do
      it 'returns successful response and trigger rate limiter' do
        execute_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'data' => { '__typename' => 'Query' } })

        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to be_nil
      end
    end

    context 'when a single ActiveRecord::QueryAborted error occurs' do
      it 're-raises ActiveRecord::QueryAborted but does not yet trigger rate limiter' do
        expect(controller)
          .to receive(:execute_query)
          .once
          .and_raise(ActiveRecord::QueryCanceled)

        execute_request

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to eq "1"
      end
    end

    context 'when 2 consecutive ActiveRecord::QueryAborted errors occur' do
      it 're-raises ActiveRecord::QueryAborted and triggers rate limiter' do
        expect(controller)
          .to receive(:execute_query)
          .twice
          .and_raise(ActiveRecord::QueryCanceled)

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
      it 'handles the error but does not trigger rate limiter' do
        expect(controller).to receive(:execute_query).and_raise(StandardError)

        execute_request

        expect(Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)).to be_falsey
        expect(current_rate_limit_value(query_sha)).to be_nil
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
    post :execute, params: { query: query, operationName: operation_name }
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
