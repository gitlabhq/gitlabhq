# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::SavedViews::Create, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:namespace_path) { project.full_path }
  let(:arguments) do
    { namespace_path: namespace_path,
      name: 'New Saved View',
      description: 'New Saved View Description',
      filters: { state: 'opened', confidential: true },
      display_settings: { hiddenMetadataKeys: ['assignee'] },
      sort: :created_asc }
  end

  let_it_be(:project) { create(:project) }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  context 'when the namespace cannot be found' do
    let(:namespace_path) { 'non/existent/path' }

    it 'raises an appropriate error' do
      expect { mutation.resolve(**arguments) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

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

    it 'creates a saved view with the specified arguments' do
      result = mutation.resolve(**arguments)
      saved_view = result[:saved_view]

      expect(saved_view).to have_attributes(
        namespace: project.project_namespace,
        name: 'New Saved View',
        display_settings: { "hiddenMetadataKeys" => ["assignee"] },
        filter_data: { "confidential" => true, "state" => "opened" },
        sort: 'created_asc',
        author: current_user
      )
    end
  end

  context 'when saved view creation fails' do
    before_all do
      project.add_planner(current_user)
    end

    let(:arguments) { { namespace_path: namespace_path, name: '', filters: { state: 'opened' } } }

    it 'returns errors without creating a saved view' do
      result = mutation.resolve(**arguments)

      expect(result[:saved_view]).to be_nil
      expect(result[:errors]).not_to be_empty
    end
  end
end
