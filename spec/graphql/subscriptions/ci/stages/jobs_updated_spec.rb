# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Ci::Stages::JobsUpdated, feature_category: :continuous_integration do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:stage_id) }
  it { expect(described_class.payload_type).to eq(Types::Ci::JobType) }

  describe '#resolve' do
    let_it_be(:project) { create(:project, :private) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:stage) { create(:ci_stage, pipeline: pipeline, project: project) }
    let_it_be(:job) { create(:ci_build, ci_stage: stage, pipeline: pipeline, project: project) }
    let_it_be(:unauthorized_user) { create(:user) }

    let(:current_user) { project.owners.first }
    let(:stage_id) { stage.to_gid }

    subject(:subscription) { resolver.resolve_with_support(stage_id: stage_id) }

    context 'when initially subscribing to the stage' do
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

      context 'when the stage does not exist' do
        let(:stage_id) { GlobalID.parse("gid://gitlab/Ci::Stage/#{non_existing_record_id}") }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'with subscription updates' do
      let(:resolver) do
        resolver_instance(described_class, obj: job, ctx: query_context, subscription_update: true)
      end

      it 'returns the job when it belongs to the stage' do
        expect(subscription).to eq(job)
      end

      context 'when job belongs to a different stage' do
        let_it_be(:other_stage) { create(:ci_stage, pipeline: pipeline, project: project, name: 'other') }
        let_it_be(:other_job) { create(:ci_build, ci_stage: other_stage, pipeline: pipeline, project: project) }

        let(:resolver) do
          resolver_instance(described_class, obj: other_job, ctx: query_context, subscription_update: true)
        end

        it 'returns skip (NO_UPDATE)' do
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end

      context 'when user cannot read the project jobs' do
        before do
          allow(Ability).to receive(:allowed?)
            .with(current_user, :read_build, project)
            .and_return(false)
        end

        it 'unsubscribes the user' do
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end

      context 'when updated_job is nil' do
        let(:resolver) do
          resolver_instance(described_class, obj: nil, ctx: query_context, subscription_update: true)
        end

        it 'returns skip (NO_UPDATE)' do
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end
    end
  end
end
