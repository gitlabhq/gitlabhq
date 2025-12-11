# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::SavedViews::Update, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:saved_view) { create(:saved_view, namespace: project.project_namespace, name: 'Saved View Name') }

  let(:arguments) { { id: saved_view.to_gid, name: 'Another Saved View Name' } }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  context 'when the user is not logged in' do
    let(:current_user) { nil }

    it 'raises an appropriate error' do
      expect { mutation.resolve(**arguments) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'when the user is logged in and can read the project' do
    before_all do
      project.add_planner(current_user)
    end

    it 'does not raise an error' do
      expect { mutation.resolve(**arguments) }.not_to raise_error
    end
  end
end
