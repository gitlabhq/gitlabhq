# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Ci::Jobs::JobCreated, feature_category: :continuous_integration do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:project_id) }
  it { expect(described_class.payload_type).to eq(Types::Ci::JobType) }

  describe '#resolve' do
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:job) { create(:ci_build, project: project) }

    let(:current_user) { job.project.owners.first }
    let(:project_id) { project.to_gid }

    subject(:subscription) { resolver.resolve_with_support(project_id: project_id) }

    context 'when initially subscribing to a projects jobs' do
      let(:resolver) { resolver_instance(described_class, ctx: query_context, subscription_update: false) }

      it 'returns nil' do
        expect(subscription).to be_nil
      end

      context 'when the user is not authorized' do
        let(:current_user) { unauthorized_user }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end

      context 'when the job does not exist' do
        let(:project_id) { GlobalID.parse("gid://gitlab/Project/#{non_existing_record_id}") }

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'with subscription updates' do
      let(:resolver) do
        resolver_instance(described_class, obj: job, ctx: query_context, subscription_update: true)
      end

      it 'returns the resolved object' do
        expect(subscription).to eq(job)
      end

      context 'when a user can not read the job' do
        before do
          allow(Ability).to receive(:allowed?)
                              .with(current_user, :read_build, project)
                              .and_return(false)
        end

        it 'unsubscribes the user' do
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end
    end
  end
end
