# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::SavedViews::Reorder, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:saved_views) { create_list(:saved_view, 3, namespace: project.project_namespace) }

  let(:arguments) do
    { id: saved_views[0].to_gid, move_after_id: saved_views[1].id }
  end

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  it { expect(described_class).to require_graphql_authorizations(:read_saved_view) }

  describe 'arguments' do
    subject { described_class }

    it { is_expected.to have_graphql_arguments(:id, :move_before_id, :move_after_id, :clientMutationId) }
  end

  context 'when the user is not logged in' do
    let(:current_user) { nil }

    it 'raises an appropriate error' do
      expect { mutation.resolve(**arguments) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'when the user is logged in and has planner permissions in the project' do
    before_all do
      project.add_planner(current_user)
    end

    it 'does not raise an error' do
      expect { mutation.resolve(**arguments) }.not_to raise_error
    end
  end

  describe 'prepare lambdas' do
    it 'prepares move_before_id to extract model_id from GlobalID' do
      move_before_arg = described_class.arguments['moveBeforeId']
      gid = saved_views[1].to_gid

      prepared_value = move_before_arg.prepare.call(gid, nil)

      expect(prepared_value).to eq(saved_views[1].id.to_i)
    end

    it 'prepares move_after_id to extract model_id from GlobalID' do
      move_after_arg = described_class.arguments['moveAfterId']
      gid = saved_views[2].to_gid

      prepared_value = move_after_arg.prepare.call(gid, nil)

      expect(prepared_value).to eq(saved_views[2].id.to_i)
    end
  end

  describe 'validations' do
    it 'requires exactly one of move_before_id or move_after_id' do
      validator = described_class.validators.find { |v| v.is_a?(Gitlab::Graphql::Validators::ExactlyOneOfValidator) }

      expect(validator).to be_present
    end
  end

  describe '#resolve' do
    before_all do
      project.add_planner(current_user)
    end

    context 'when saved views are disabled' do
      before do
        stub_feature_flags(work_items_saved_views: false)
      end

      it 'returns an error' do
        result = mutation.resolve(**arguments)

        expect(result[:saved_view]).to be_nil
        expect(result[:errors]).to eq(['Saved views are not enabled for this namespace.'])
      end
    end

    context 'when valid arguments are provided' do
      let!(:user_saved_view1) do
        create(:user_saved_view, user: current_user, saved_view: saved_views[0],
          namespace: saved_views[0].namespace, relative_position: 1000)
      end

      let!(:user_saved_view2) do
        create(:user_saved_view, user: current_user, saved_view: saved_views[1],
          namespace: saved_views[1].namespace, relative_position: 2000)
      end

      it 'reorders the saved view successfully with move_after_id' do
        result = mutation.resolve(id: saved_views[0].to_gid, move_after_id: saved_views[1].id)

        expect(result[:errors]).to be_empty
        expect(result[:saved_view]).to eq(saved_views[0])
      end

      it 'reorders the saved view successfully with move_before_id' do
        result = mutation.resolve(id: saved_views[1].to_gid, move_before_id: saved_views[0].id)

        expect(result[:errors]).to be_empty
        expect(result[:saved_view]).to eq(saved_views[1])
      end
    end
  end
end
