# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ml::ExperimentDetailResolver, feature_category: :mlops do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { build(:project) }
    let_it_be(:experiment) { create(:ml_experiments, project: project) }
    let_it_be(:owner) { project.owner }

    let(:current_user) { owner }
    let(:args) { { id: global_id_of(experiment) } }
    let(:read_model_experiments) { true }

    subject { force(resolve(described_class, ctx: { current_user: current_user }, args: args)) }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :read_model_experiments, project)
                          .and_return(read_model_experiments)
    end

    context 'when user is allowed and experiment exists' do
      it { is_expected.to eq(experiment) }

      context 'when user is nil' do
        let(:current_user) { nil }

        it { is_expected.to eq(experiment) }
      end
    end

    context 'when user does not have permission' do
      let(:read_model_experiments) { false }

      it { is_expected.to be_nil }
    end

    context 'when experiment does not exist' do
      let(:args) { { id: global_id_of(id: non_existing_record_id, model_name: 'Ml::Experiment') } }

      it { is_expected.to be_nil }
    end
  end
end
