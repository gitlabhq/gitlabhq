# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlChannel, feature_category: :api do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:user) { create(:user).tap { |u| merge_request.project.add_developer(u) } }

  let_it_be(:read_api_token) { create(:personal_access_token, scopes: ['read_api'], user: user) }
  let_it_be(:read_user_token) { create(:personal_access_token, scopes: ['read_user'], user: user) }
  let_it_be(:read_api_and_read_user_token) do
    create(:personal_access_token, scopes: %w[read_user read_api], user: user)
  end

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
      before do
        stub_action_cable_connection current_user: user, access_token: access_token
      end

      context 'with an api scoped personal access token' do
        let(:access_token) { read_api_token }

        it 'subscribes to the given graphql subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_confirmed
          expect(subscription.streams).to include(/graphql-event::mergeRequestReviewersUpdated:issuableId/)
        end
      end

      context 'with a read_user personal access token' do
        let(:access_token) { read_user_token }

        it 'does not subscribe to the given graphql subscription' do
          subscribe(subscribe_params)

          expect(subscription).not_to be_confirmed
        end
      end

      context 'with a read_api and read_user personal access token' do
        let(:access_token) { read_api_and_read_user_token }

        it 'subscribes to the given graphql subscription' do
          subscribe(subscribe_params)

          expect(subscription).to be_confirmed
          expect(subscription.streams).to include(/graphql-event::mergeRequestReviewersUpdated:issuableId/)
        end
      end
    end
  end
end
