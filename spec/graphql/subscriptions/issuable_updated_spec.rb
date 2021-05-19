# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::IssuableUpdated do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:issuable_id) }
  it { expect(described_class.payload_type).to eq(Types::IssuableType) }

  describe '#resolve' do
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:issue) { create(:issue) }

    let(:current_user) { issue.author }
    let(:issuable_id) { issue.to_gid }

    subject { resolver.resolve_with_support(issuable_id: issuable_id) }

    context 'initial subscription' do
      let(:resolver) { resolver_instance(described_class, ctx: { current_user: current_user }, subscription_update: false) }

      it 'returns nil' do
        expect(subject).to eq(nil)
      end

      context 'when user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'raises an exception' do
          expect { subject }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when issue does not exist' do
        let(:issuable_id) { GlobalID.parse("gid://gitlab/Issue/#{non_existing_record_id}") }

        it 'raises an exception' do
          expect { subject }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when a GraphQL::ID_TYPE is provided' do
        let(:issuable_id) { issue.to_gid.to_s }

        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
        end
      end
    end

    context 'subscription updates' do
      let(:resolver) { resolver_instance(described_class, obj: issue, ctx: { current_user: current_user }, subscription_update: true) }

      it 'returns the resolved object' do
        expect(subject).to eq(issue)
      end

      context 'when user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'unsubscribes the user' do
          expect { subject }.to throw_symbol(:graphql_subscription_unsubscribed)
        end
      end
    end
  end
end
