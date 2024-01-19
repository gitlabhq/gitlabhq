# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ml::ModelDetailResolver, feature_category: :mlops do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:model) { create(:ml_models, project: project) }
    let_it_be(:owner) { project.owner }

    let(:current_user) { owner }
    let(:args) { { id: global_id_of(model) } }
    let(:read_model_registry) { true }

    subject { force(resolve(described_class, ctx: { current_user: current_user }, args: args)) }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :read_model_registry, project)
                          .and_return(read_model_registry)
    end

    context 'when user is allowed and model exists' do
      it { is_expected.to eq(model) }

      context 'when user is nil' do
        let(:current_user) { nil }

        it { is_expected.to eq(model) }
      end
    end

    context 'when user does not have permission' do
      let(:read_model_registry) { false }

      it { is_expected.to be_nil }
    end

    context 'when model does not exist' do
      let(:args) { { id: global_id_of(id: non_existing_record_id, model_name: 'Ml::Model') } }

      it { is_expected.to be_nil }
    end
  end
end
