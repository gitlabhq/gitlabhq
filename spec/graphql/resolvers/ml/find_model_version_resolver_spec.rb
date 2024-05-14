# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ml::FindModelVersionResolver, feature_category: :mlops do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:model) { create(:ml_models, project: project) }
    let_it_be(:model_version) { create(:ml_model_versions, model: model) }
    let_it_be(:another_model_version) { create(:ml_model_versions) }
    let_it_be(:owner) { project.owner }

    let(:current_user) { owner }
    let(:args) { { model_version_id: global_id_of(model_version) } }
    let(:read_model_registry) { true }

    subject { force(resolve(described_class, obj: model, ctx: { current_user: current_user }, args: args)) }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :read_model_registry, project)
                          .and_return(read_model_registry)
    end

    context 'when user is allowed and model version exists and belongs to model' do
      it { is_expected.to eq(model_version) }

      context 'when user is nil' do
        let(:current_user) { nil }

        it { is_expected.to eq(model_version) }
      end
    end

    context 'when user does not have permission' do
      let(:read_model_registry) { false }

      it { is_expected.to be_nil }
    end

    context 'when model version exists but does not belong to model' do
      let(:args) { { model_version_id: global_id_of(another_model_version) } }

      it { is_expected.to be_nil }
    end

    context 'when model version does not exist' do
      let(:args) { { model_version_id: global_id_of(id: non_existing_record_id, model_name: 'Ml::ModelVersion') } }

      it { is_expected.to be_nil }
    end
  end
end
