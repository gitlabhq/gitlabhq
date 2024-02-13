# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ml::FindModelVersionsResolver, feature_category: :mlops do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:model) { create(:ml_models, project: project) }
    let_it_be(:model_versions) { create_list(:ml_model_versions, 2, model: model, project: model.project) }
    let_it_be(:user) { project.owner }

    let(:args) { { version: '1.0', orderBy: 'CREATED_AT', sort: 'desc', invalid: 'blah' } }

    subject(:resolve_model_versions) do
      force(resolve(described_class, obj: model, ctx: { current_user: user }, args: args))&.to_a
    end

    context 'when user is allowed and model exists' do
      it { is_expected.to eq(model_versions.reverse) }

      it 'only passes name, sort_by and order to finder' do
        expect(::Projects::Ml::ModelVersionFinder).to receive(:new)
          .with(model, { version: '1.0', order_by: 'created_at', sort: 'desc' })
          .and_call_original

        resolve_model_versions
      end
    end

    context 'when user does not have permission' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(user, :read_model_registry, project)
                            .and_return(false)
      end

      it { is_expected.to be_nil }
    end
  end
end
