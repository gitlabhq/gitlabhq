# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlChannel, feature_category: :api do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user, developer_of: merge_request.project) }
  let_it_be(:read_api_token) { create(:personal_access_token, scopes: ['read_api'], user: user) }
  let_it_be(:read_user_token) { create(:personal_access_token, scopes: ['read_user'], user: user) }
  let_it_be(:read_api_and_read_user_token) do
    create(:personal_access_token, scopes: %w[read_user read_api], user: user)
  end

  let_it_be(:expired_token) { create(:personal_access_token, :expired, scopes: %w[read_api], user: user) }
  let_it_be(:revoked_token) { create(:personal_access_token, :revoked, scopes: %w[read_api], user: user) }

  describe '#subscribed' do
    let(:query) do
      <<~GRAPHQL
      subscription mergeRequestReviewersUpdated($issuableId: IssuableID!) {
        mergeRequestReviewersUpdated(issuableId: $issuableId) {
          ... on MergeRequest { id title }
        }
      }
      GRAPHQL
    end

    let(:subscribe_params) do
      {
        query: query,
        variables: { issuableId: merge_request.to_global_id }
      }
    end

    before do
      stub_action_cable_connection current_user: user
    end

    it 'subscribes to the given graphql subscription' do
      subscribe(subscribe_params)

      expect(subscription).to be_confirmed
      expect(subscription.streams).to include(/graphql-event::mergeRequestReviewersUpdated:issuableId/)
    end

    context 'with a personal access token' do
      let(:app_context) { Gitlab::ApplicationContext.current }

      before do
        stub_action_cable_connection current_user: user, access_token: access_token
      end

      context 'with an api scoped personal access token' do
        let(:access_token) { read_api_token }

        it 'subscribes to the given graphql subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_confirmed
          expect(subscription.streams).to include(/graphql-event::mergeRequestReviewersUpdated:issuableId/)
          expect(app_context.keys).not_to include('meta.auth_fail_reason', 'meta.auth_fail_token_id')
        end
      end

      context 'with a read_user personal access token' do
        let(:access_token) { read_user_token }

        it 'does not subscribe to the given graphql subscription' do
          subscribe(subscribe_params)

          expect(subscription).not_to be_confirmed
          expect(app_context['meta.auth_fail_reason']).to eq('insufficient_scope')
          expect(app_context['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{access_token.id}")
        end
      end

      context 'with a read_api and read_user personal access token' do
        let(:access_token) { read_api_and_read_user_token }

        it 'subscribes to the given graphql subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_confirmed
          expect(subscription.streams).to include(/graphql-event::mergeRequestReviewersUpdated:issuableId/)
          expect(app_context.keys).not_to include('meta.auth_fail_reason', 'meta.auth_fail_token_id')
        end
      end

      context 'with an expired read_user personal access token' do
        let(:access_token) { expired_token }

        it 'does not subscribe to the given graphql subscription' do
          subscribe(subscribe_params)

          expect(subscription).not_to be_confirmed
          expect(app_context['meta.auth_fail_reason']).to eq('token_expired')
          expect(app_context['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{access_token.id}")
        end
      end

      context 'with a revoked read_user personal access token' do
        let(:access_token) { revoked_token }

        it 'does not subscribe to the given graphql subscription' do
          subscribe(subscribe_params)

          expect(subscription).not_to be_confirmed
          expect(app_context['meta.auth_fail_reason']).to eq('token_revoked')
          expect(app_context['meta.auth_fail_token_id']).to eq("PersonalAccessToken/#{access_token.id}")
        end
      end
    end

    describe 'metrics' do
      before do
        stub_action_cable_connection current_user: create(:user)
      end

      it 'does not track unauthorized subscriptions as errors' do
        expect(Gitlab::Metrics::RailsSlis.graphql_query_apdex).not_to receive(:increment)

        expect(Gitlab::Metrics::RailsSlis.graphql_query_error_rate).to receive(:increment).with({
          labels: anything,
          error: false
        })

        subscribe(subscribe_params)

        expect(transmissions.first['result']).to match(a_hash_including(
          'errors' => [
            a_hash_including(
              'message' => 'Unauthorized subscription'
            )
          ]
        ))
      end
    end
  end
end
