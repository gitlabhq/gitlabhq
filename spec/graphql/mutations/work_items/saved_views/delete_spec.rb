# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::SavedViews::Delete, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, developers: [current_user]) }
  let_it_be(:project) { create(:project, group: group, developers: [current_user]) }

  let_it_be(:saved_view) do
    create(:saved_view, namespace: project.project_namespace, created_by_id: current_user.id, name: 'Test View')
  end

  let_it_be(:user_saved_view) do
    create(:user_saved_view, saved_view: saved_view, user: current_user, namespace: project.project_namespace)
  end

  let(:saved_view_gid) { saved_view.to_global_id.to_s }

  subject(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  describe '#resolve' do
    context 'when user has permission to delete' do
      it 'deletes the saved view' do
        expect { mutation.resolve(id: saved_view_gid) }.to change { WorkItems::SavedViews::SavedView.count }.by(-1)
      end

      it 'returns the deleted saved view' do
        result = mutation.resolve(id: saved_view_gid)

        expect(result[:saved_view]).to eq(saved_view)
        expect(result[:errors]).to be_empty
      end

      it 'cascades delete to user_saved_views' do
        expect { mutation.resolve(id: saved_view_gid) }.to change { WorkItems::SavedViews::UserSavedView.count }.by(-1)
      end
    end

    context 'when saved view does not exist' do
      let(:invalid_gid) { "gid://gitlab/WorkItems::SavedViews::SavedView/999999" }

      it 'raises an error' do
        expect { mutation.resolve(id: invalid_gid) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user does not have permission to delete' do
      let_it_be(:other_user) { create(:user) }
      let(:current_user) { other_user }

      it 'raises an error' do
        expect { mutation.resolve(id: saved_view_gid) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it 'raises an error' do
        expect { mutation.resolve(id: saved_view_gid) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when saved views are not enabled for the namespace' do
      before do
        stub_feature_flags(work_items_saved_views: false)
      end

      it 'returns an error without deleting' do
        result = mutation.resolve(id: saved_view_gid)

        expect(result[:saved_view]).to be_nil
        expect(result[:errors]).to eq(['Saved views are not enabled for this namespace.'])
      end

      it 'does not delete the saved view' do
        expect { mutation.resolve(id: saved_view_gid) }.not_to change { WorkItems::SavedViews::SavedView.count }
      end
    end

    context 'when deleting a view with multiple user subscriptions' do
      let_it_be(:other_user) { create(:user) }
      let_it_be(:other_user_saved_view) do
        create(:user_saved_view, saved_view: saved_view, user: other_user, namespace: project.project_namespace)
      end

      it 'deletes all associated user_saved_views' do
        expect { mutation.resolve(id: saved_view_gid) }.to change { WorkItems::SavedViews::UserSavedView.count }.by(-2)
      end
    end

    context 'with a group namespace saved view' do
      let_it_be(:group_saved_view) do
        create(:saved_view, namespace: group, created_by_id: current_user.id)
      end

      let(:group_saved_view_gid) { group_saved_view.to_global_id.to_s }

      it 'successfully deletes group saved views' do
        result = mutation.resolve(id: group_saved_view_gid)

        expect(result[:saved_view]).to eq(group_saved_view)
        expect(result[:errors]).to be_empty
      end
    end
  end
end
