# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::WorkItems::SavedViewUpdated, feature_category: :planning_views do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:saved_view_id) }
  it { expect(described_class.payload_type).to eq(Types::WorkItems::SavedViews::SavedViewType) }

  describe '#resolve' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:author) { create(:user, guest_of: group) }
    let_it_be(:member) { create(:user, guest_of: group) }
    let_it_be(:non_member) { create(:user) }
    let_it_be_with_reload(:saved_view) { create(:saved_view, namespace: group, author: author, private: false) }

    let(:current_user) { member }
    let(:saved_view_id) { saved_view.to_gid }

    subject(:result) { resolver.resolve_with_support(saved_view_id: saved_view_id) }

    context 'when subscribing' do
      let(:resolver) { resolver_instance(described_class, ctx: query_context, subscription_update: false) }

      it 'returns nil' do
        expect(result).to be_nil
      end

      context 'when the user cannot read the namespace' do
        let(:current_user) { non_member }

        it 'raises an exception' do
          expect { result }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when the user is not signed in' do
        let(:current_user) { nil }

        it 'raises an exception' do
          expect { result }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when the saved view does not exist' do
        let(:saved_view_id) do
          GlobalID.parse("gid://gitlab/WorkItems::SavedViews::SavedView/#{non_existing_record_id}")
        end

        it 'raises an exception' do
          expect { result }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when the saved view is private' do
        let_it_be(:saved_view) { create(:saved_view, namespace: group, author: author, private: true) }

        it 'raises an exception for a member who is not the author' do
          expect { result }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when the work_items_realtime feature flag is disabled' do
        before do
          stub_feature_flags(work_items_realtime: false)
        end

        it 'raises an exception' do
          expect { result }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'when receiving an update' do
      let(:resolver) do
        resolver_instance(described_class, obj: saved_view, ctx: query_context, subscription_update: true)
      end

      it 'returns the saved view' do
        expect(result).to eq(saved_view)
      end

      context 'when the user is not a namespace member' do
        let(:current_user) { non_member }

        it 'unsubscribes the user' do
          expect(result).to be_an(GraphQL::Execution::Skip)
        end
      end

      context 'when the saved view has become private' do
        before do
          saved_view.update!(private: true)
        end

        it 'unsubscribes a member who is not the author' do
          expect(result).to be_an(GraphQL::Execution::Skip)
        end

        context 'when the subscriber is the author' do
          let(:current_user) { author }

          it 'delivers the saved view' do
            expect(result).to eq(saved_view)
          end
        end
      end

      context 'when the work_items_realtime feature flag is disabled' do
        before do
          stub_feature_flags(work_items_realtime: false)
        end

        it 'unsubscribes the user' do
          expect(result).to be_an(GraphQL::Execution::Skip)
        end
      end
    end
  end
end
