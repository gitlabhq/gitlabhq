# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Ci::Pipelines::StatusesUpdated, feature_category: :continuous_integration do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:project_id) }
  it { expect(described_class.payload_type).to eq(Types::Ci::PipelineType) }

  describe '#resolve' do
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:other_project_pipeline) { create(:ci_pipeline) }

    let(:current_user) { project.owners.first }
    let(:project_id) { project.to_gid }

    subject(:subscription) { resolver.resolve_with_support(project_id: project_id) }

    context 'when initially subscribing to the project pipelines' do
      let(:resolver) { resolver_instance(described_class, ctx: query_context, subscription_update: false) }

      it 'returns nil' do
        expect(subscription).to be_nil
      end

      context 'when the user is unauthorized' do
        let(:current_user) { unauthorized_user }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when the project does not exist' do
        let(:project_id) { GlobalID.parse("gid://gitlab/Project/#{non_existing_record_id}") }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'with subscription updates' do
      let(:resolver) do
        resolver_instance(described_class, obj: pipeline, ctx: query_context, subscription_update: true)
      end

      it 'returns the resolved pipeline' do
        expect(subscription).to eq(pipeline)
      end

      context 'when pipeline belongs to a different project' do
        let(:resolver) do
          resolver_instance(described_class, obj: other_project_pipeline, ctx: query_context, subscription_update: true)
        end

        it 'unsubscribes the user' do
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end

      context 'when user can not read the specific pipeline' do
        before do
          # Let all checks pass by default
          allow(Ability).to receive(:allowed?).and_call_original

          allow(Ability).to receive(:allowed?)
            .with(current_user, :read_pipeline, pipeline)
            .and_return(false)
        end

        it 'filters out the update' do
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end
    end
  end
end
