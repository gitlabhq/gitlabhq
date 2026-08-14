# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::WorkItems::NamespaceWorkItemChanges, feature_category: :planning_views do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:namespace_id) }
  it { expect(described_class.payload_type).to eq(Types::WorkItems::NamespaceWorkItemChangesPayloadType) }

  describe '#resolve' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:work_item) { create(:work_item, project: project) }
    let_it_be(:member) { create(:user).tap { |u| group.add_guest(u) } }
    let_it_be(:non_member) { create(:user) }

    let(:payload) { { work_item_id: work_item.id, action: :updated } }
    let(:current_user) { member }
    let(:namespace_id) { group.to_gid }

    subject(:result) { resolver.resolve_with_support(namespace_id: namespace_id) }

    context 'when subscribing' do
      let(:resolver) { resolver_instance(described_class, ctx: query_context, subscription_update: false) }

      it 'returns nil' do
        expect(result).to be_nil
      end

      context 'when user is not a namespace member' do
        let(:current_user) { non_member }

        it 'raises an exception' do
          expect { result }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when namespace does not exist' do
        let(:namespace_id) { GlobalID.parse("gid://gitlab/Group/#{non_existing_record_id}") }

        it 'raises an exception' do
          expect { result }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when the namespace is a project namespace' do
        let_it_be(:other_project) { create(:project) }
        let(:namespace_id) { other_project.project_namespace.to_gid }

        context 'when the user is a project member' do
          before_all do
            other_project.add_guest(member)
          end

          it 'returns nil' do
            expect(result).to be_nil
          end
        end

        context 'when the user is not a project member' do
          it 'raises an exception' do
            expect { result }.to raise_error(GraphQL::ExecutionError)
          end
        end
      end

      context 'when the namespace is a user namespace' do
        let_it_be(:user_namespace) { create(:namespace) }
        let(:namespace_id) { user_namespace.to_gid }

        context 'when the user owns the namespace' do
          let(:current_user) { user_namespace.owner }

          it 'returns nil' do
            expect(result).to be_nil
          end
        end

        context 'when the user does not own the namespace' do
          it 'raises an exception' do
            expect { result }.to raise_error(GraphQL::ExecutionError)
          end
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
        resolver_instance(described_class, obj: payload, ctx: query_context, subscription_update: true)
      end

      it 'returns the payload' do
        expect(result).to eq(payload)
      end

      context 'when user is not a namespace member' do
        let(:current_user) { non_member }

        it 'unsubscribes the user' do
          expect(result).to be_an(GraphQL::Execution::Skip)
        end
      end

      context 'when namespace does not exist' do
        let(:namespace_id) { GlobalID.parse("gid://gitlab/Group/#{non_existing_record_id}") }

        it 'unsubscribes the user' do
          expect(result).to be_an(GraphQL::Execution::Skip)
        end
      end

      # No per-item authorization by design; unreadable items are filtered at the trigger.
      context 'when the work item no longer exists' do
        let(:payload) { { work_item_id: non_existing_record_id, action: :deleted } }

        it 'delivers the event to the member' do
          expect(result).to eq(payload)
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
