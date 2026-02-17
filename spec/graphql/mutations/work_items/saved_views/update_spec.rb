# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::SavedViews::Update, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:saved_view) { create(:saved_view, namespace: project.project_namespace, name: 'Saved View Name') }

  let(:arguments) { { id: saved_view.to_gid, name: 'Another Saved View Name' } }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(:update_saved_view) }

  context 'when the user is not logged in' do
    let(:current_user) { nil }

    it 'raises an appropriate error' do
      expect { mutation.resolve(**arguments) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'when the user does not have permission' do
    it 'raises an appropriate error' do
      expect { mutation.resolve(**arguments) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'when the user has permission' do
    before_all do
      project.add_planner(current_user)
    end

    context 'when the update is successful' do
      it 'updates the saved view and returns no errors' do
        result = mutation.resolve(**arguments)

        expect(result[:errors]).to be_empty
        expect(result[:saved_view].name).to eq('Another Saved View Name')
      end
    end

    context 'when the update fails' do
      let(:arguments) { { id: saved_view.to_gid, name: '' } }

      it 'returns errors and does not update the saved view' do
        result = mutation.resolve(**arguments)

        expect(result[:saved_view]).to be_nil
        expect(result[:errors]).to be_present
      end
    end

    context 'with spam checking' do
      before do
        allow(mutation).to receive(:check_spam_action_response!)
      end

      it 'checks for spam on successful update' do
        mutation.resolve(**arguments)

        expect(mutation).to have_received(:check_spam_action_response!).with(saved_view)
      end
    end
  end

  context 'when saved view does not exist' do
    let(:arguments) { { id: "gid://gitlab/WorkItems::SavedViews::SavedView/#{non_existing_record_id}" } }

    before_all do
      project.add_planner(current_user)
    end

    it 'raises an appropriate error' do
      expect { mutation.resolve(**arguments) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  context 'when saved view belongs to a different namespace' do
    let_it_be(:other_project) { create(:project) }
    let_it_be(:other_saved_view) { create(:saved_view, namespace: other_project.project_namespace) }
    let(:arguments) { { id: other_saved_view.to_gid, name: 'New Name' } }

    before_all do
      project.add_planner(current_user)
    end

    it 'raises an appropriate error' do
      expect { mutation.resolve(**arguments) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end
end
