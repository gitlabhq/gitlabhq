# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ml::FindExperimentsResolver, feature_category: :mlops do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { build(:project) }
    let_it_be(:experiments) { create_list(:ml_experiments, 2, project: project) }
    let_it_be(:experiment_in_another_project) { create(:ml_experiments) }
    let_it_be(:owner) { project.owner }

    let(:current_user) { owner }
    let(:args) { { name: 'experiment', orderBy: 'CREATED_AT', sort: 'desc', invalid: 'blah' } }
    let(:read_model_experiments) { true }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :read_model_experiments, project)
                          .and_return(read_model_experiments)
    end

    subject(:resolve_experiments) do
      force(resolve(described_class, obj: project, ctx: { current_user: current_user }, args: args))&.to_a
    end

    context 'when user is allowed and experiment exists' do
      it { is_expected.to eq(experiments.reverse) }

      it 'only passes name, sort_by and order to finder' do
        expect(::Projects::Ml::ExperimentFinder).to receive(:new)
                                                      .with(project, {
                                                        name: 'experiment',
                                                        order_by: 'created_at',
                                                        sort: 'desc',
                                                        with_candidate_count: true
                                                      })
                                                      .and_call_original

        resolve_experiments
      end

      context 'when user is nil' do
        let(:current_user) { nil }

        it 'processes the request' do
          expect(::Projects::Ml::ExperimentFinder).to receive(:new)
                                                        .with(project, {
                                                          name: 'experiment',
                                                          order_by: 'created_at',
                                                          sort: 'desc',
                                                          with_candidate_count: true
                                                        })
                                                        .and_call_original

          resolve_experiments
        end
      end
    end

    context 'when user does not have permission' do
      let(:read_model_experiments) { false }

      it { is_expected.to be_nil }
    end
  end
end
