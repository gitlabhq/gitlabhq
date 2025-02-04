# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::User::MergeRequestUpdated, feature_category: :code_review_workflow do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:user_id) }
  it { expect(described_class.payload_type).to eq(Types::MergeRequestType) }

  describe '#resolve' do
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:merge_request) { create(:merge_request) }

    let(:current_user) { merge_request.author }
    let(:user_id) { merge_request.author.to_gid }

    subject(:subscription) { resolver.resolve_with_support(user_id: user_id) }

    context 'for initial subscription' do
      let(:resolver) { resolver_instance(described_class, ctx: query_context, subscription_update: false) }

      it 'returns nil' do
        expect(subscription).to be_nil
      end

      context 'when user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when user does not exist' do
        let(:user_id) { GlobalID.parse("gid://gitlab/User/#{non_existing_record_id}") }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'with subscription updates' do
      let(:resolver) do
        resolver_instance(described_class, obj: merge_request, ctx: query_context, subscription_update: true)
      end

      it 'returns the resolved object' do
        expect(subscription).to eq(merge_request)
      end

      context 'when user can not read the merge request' do
        before do
          allow(Ability).to receive(:allowed?)
                  .with(current_user, :read_merge_request, merge_request)
                  .and_return(false)
        end

        it 'unsubscribes the user' do
          # GraphQL::Execution::Skip is returned when unsubscribed
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end

      context 'when user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'unsubscribes the user' do
          # GraphQL::Execution::Skip is returned when unsubscribed
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end
    end
  end
end
