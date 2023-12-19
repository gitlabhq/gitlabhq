# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ml::ModelDetailResolver, feature_category: :mlops do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:model) { create(:ml_models, project: project) }
    let_it_be(:user) { project.owner }

    let(:args) { { id: global_id_of(model) } }
    let(:read_model_registry) { true }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(user, :read_model_registry, project)
                          .and_return(read_model_registry)
    end

    subject { force(resolve(described_class, ctx: { current_user: user }, args: args)) }

    context 'when user is allowed and model exists' do
      it { is_expected.to eq(model) }
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
