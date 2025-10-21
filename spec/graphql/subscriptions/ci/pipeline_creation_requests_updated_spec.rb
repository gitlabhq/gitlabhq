# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Ci::PipelineCreationRequestsUpdated, feature_category: :continuous_integration do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:merge_request_id) }
  it { expect(described_class.payload_type).to eq(Types::MergeRequestType) }

  describe '#resolve' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:guest_user) { create(:user) }
    let_it_be(:developer_user) { create(:user) }

    let(:current_user) { merge_request.author }
    let(:merge_request_id) { merge_request.to_gid }

    before_all do
      project.add_guest(guest_user)
      project.add_developer(developer_user)
    end

    subject(:subscription) { resolver.resolve_with_support(merge_request_id: merge_request_id) }

    context 'when initially subscribing to the merge request' do
      let(:resolver) { resolver_instance(described_class, ctx: query_context, subscription_update: false) }

      it 'returns nil' do
        expect(subscription).to be_nil
      end

      context 'when user has read_merge_request permission' do
        let(:current_user) { developer_user }

        it 'returns nil' do
          expect(subscription).to be_nil
        end
      end

      context 'when user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when user is a guest' do
        let(:current_user) { guest_user }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when merge request does not exist' do
        let(:merge_request_id) { GlobalID.parse("gid://gitlab/MergeRequest/#{non_existing_record_id}") }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'with subscription updates' do
      let(:resolver) do
        resolver_instance(described_class, obj: merge_request, ctx: query_context, subscription_update: true)
      end

      let(:current_user) { developer_user }

      it 'returns the resolved merge request object' do
        expect(subscription).to eq(merge_request)
      end

      it 'subscription payload matches MergeRequestType structure' do
        expect(subscription).to be_a(MergeRequest)
        expect(subscription.id).to eq(merge_request.id)
        expect(subscription.iid).to eq(merge_request.iid)
      end

      context 'when user cannot read the merge request' do
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
    end
  end
end
