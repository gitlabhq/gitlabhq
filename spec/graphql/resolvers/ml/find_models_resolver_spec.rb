# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ml::FindModelsResolver, feature_category: :mlops do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:models) { create_list(:ml_models, 2, project: project) }
    let_it_be(:model_in_another_project) { create(:ml_models) }
    let_it_be(:owner) { project.owner }

    let(:current_user) { owner }
    let(:args) { { name: 'model', orderBy: 'CREATED_AT', sort: 'desc', invalid: 'blah' } }
    let(:read_model_registry) { true }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability).to receive(:allowed?)
                          .with(current_user, :read_model_registry, project)
                          .and_return(read_model_registry)
    end

    subject(:resolve_models) do
      force(resolve(described_class, obj: project, ctx: { current_user: current_user }, args: args))&.to_a
    end

    context 'when user is allowed and model exists' do
      it { is_expected.to eq(models.reverse) }

      it 'only passes name, sort_by and order to finder' do
        expect(::Projects::Ml::ModelFinder).to receive(:new)
                                                 .with(project, { name: 'model', order_by: 'created_at',
sort: 'desc' })
                                                 .and_call_original

        resolve_models
      end

      context 'when user is nil' do
        let(:current_user) { nil }

        it 'processes the request' do
          expect(::Projects::Ml::ModelFinder).to receive(:new)
                                                   .with(project, { name: 'model', order_by: 'created_at',
                                                                    sort: 'desc' })
                                                   .and_call_original

          resolve_models
        end
      end
    end

    context 'when user does not have permission' do
      let(:read_model_registry) { false }

      it { is_expected.to be_nil }
    end
  end
end
