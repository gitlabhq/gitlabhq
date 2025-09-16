# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::Ci::PipelineSchedule::StatusUpdated, feature_category: :continuous_integration do
  include GraphqlHelpers

  it { expect(described_class).to have_graphql_arguments(:project_id) }
  it { expect(described_class.payload_type).to eq(Types::Ci::PipelineScheduleType) }

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:other_project) { create(:project) }
    let_it_be(:schedule1) { create(:ci_pipeline_schedule, project: project, owner: user) }
    let_it_be(:schedule2) { create(:ci_pipeline_schedule, project: project, owner: user) }
    let_it_be(:other_schedule) { create(:ci_pipeline_schedule, project: other_project, owner: unauthorized_user) }

    let(:current_user) { user }
    let(:project_id) { project.to_gid }

    before_all do
      project.add_owner(user)
      other_project.add_owner(unauthorized_user)
    end

    subject(:subscription) { resolver.resolve_with_support(project_id: project_id) }

    context 'when initially subscribing to a projects pipeline schedules' do
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

      context 'when user can not read the schedule' do
        before do
          allow(Ability).to receive(:allowed?)
                  .with(current_user, :read_pipeline_schedule, project)
                  .and_return(false)
        end

        it 'raises an exception' do
          expect { subscription }.to raise_error(GraphQL::ExecutionError)
        end
      end
    end

    context 'with subscription updates' do
      let(:updated_schedule) { schedule1 }
      let(:resolver) do
        resolver_instance(described_class, obj: updated_schedule, ctx: query_context, subscription_update: true)
      end

      context 'when the updated schedule is in the subscribed list' do
        it 'returns the updated schedule' do
          expect(subscription).to eq(updated_schedule)
        end
      end

      context 'when the updated schedule belongs to a different project' do
        let(:updated_schedule) { other_schedule }

        it 'unsubscribes the user' do
          # GraphQL::Execution::Skip is returned when unsubscribed
          expect(subscription).to be_an(GraphQL::Execution::Skip)
        end
      end

      context 'with multiple schedules in the project' do
        context 'when schedule1 updates' do
          let(:updated_schedule) { schedule1 }

          it 'returns schedule1' do
            expect(subscription).to eq(schedule1)
          end
        end

        context 'when schedule2 updates' do
          let(:updated_schedule) { schedule2 }

          it 'returns schedule2' do
            expect(subscription).to eq(schedule2)
          end
        end
      end
    end
  end
end
