# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::SavedViews::Reorder, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:saved_views) { create_list(:saved_view, 3, namespace: project.project_namespace) }

  let(:arguments) do
    { id: saved_views[0].to_gid, move_before_id: saved_views[1].to_gid, move_after_id: saved_views[2].to_gid }
  end

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

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

      expect(prepared_value).to eq(saved_views[1].id.to_s)
    end

    it 'prepares move_after_id to extract model_id from GlobalID' do
      move_after_arg = described_class.arguments['moveAfterId']
      gid = saved_views[2].to_gid

      prepared_value = move_after_arg.prepare.call(gid, nil)

      expect(prepared_value).to eq(saved_views[2].id.to_s)
    end
  end
end
