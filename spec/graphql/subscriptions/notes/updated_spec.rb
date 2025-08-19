# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Notes::Updated, feature_category: :team_planning do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:noteable_id) }
  it { expect(described_class.payload_type).to eq(Types::Notes::NoteType) }

  describe '#resolve' do
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:note) { create(:note) }

    let(:current_user) { note.author }
    let(:noteable_id) { note.noteable.to_gid }

    subject(:subscription) { resolver.resolve_with_support(noteable_id: noteable_id) }

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
    end

    context 'with subscription updates' do
      let(:resolver) do
        resolver_instance(described_class, obj: note, ctx: query_context, subscription_update: true)
      end

      before do
        lb_session = ::Gitlab::Database::LoadBalancing::SessionMap.current(note.load_balancer)

        allow(lb_session).to receive(:use_primary).and_call_original

        allow(::Gitlab::Database::LoadBalancing::SessionMap).to receive(:current).and_return(lb_session)
      end

      it 'returns the resolved object' do
        expect(subscription).to eq(note)
      end

      context 'when user can not read the merge request' do
        before do
          allow(Ability).to receive(:allowed?)
                  .with(current_user, :read_issue, note.noteable)
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
