# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::SavedViews::Unsubscribe, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, planner_of: [project]) }
  let_it_be(:saved_view) { create(:saved_view, namespace: project.project_namespace) }

  let(:current_ctx) { { current_user: current_user } }

  def resolve_mutation(**args)
    resolve(described_class, args: args, ctx: current_ctx)
  end

  describe '#resolve' do
    context 'when the user is not logged in' do
      let(:current_ctx) { { current_user: nil } }

      it 'raises an appropriate error' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          resolve_mutation(id: saved_view.to_global_id)
        end
      end
    end

    context 'when the user is a guest' do
      let_it_be(:guest_user) { create(:user, guest_of: [project]) }
      let(:current_ctx) { { current_user: guest_user } }

      it 'allows unsubscription from the saved view' do
        create(:user_saved_view, user: guest_user, saved_view: saved_view)

        result = resolve_mutation(id: saved_view.to_global_id)

        expect(result[:saved_view]).to eq(saved_view)
      end
    end

    context 'when saved views are not enabled for the namespace' do
      before do
        stub_feature_flags(work_items_saved_views: false)
      end

      it 'returns an error' do
        result = resolve_mutation(id: saved_view.to_global_id)

        expect(result[:saved_view]).to be_nil
        expect(result[:errors]).to eq(['Saved views are not enabled for this namespace.'])
      end
    end

    context 'when the user has permission' do
      context 'when subscribed to the saved view' do
        let_it_be(:user_saved_view) do
          create(:user_saved_view, user: current_user, saved_view: saved_view, namespace: project.project_namespace)
        end

        it 'successfully unsubscribes from the saved view' do
          result = resolve_mutation(id: saved_view.to_global_id)

          expect(result[:saved_view]).to eq(saved_view)
        end

        it 'deletes the user saved view record' do
          expect { resolve_mutation(id: saved_view.to_global_id) }
            .to change { WorkItems::SavedViews::UserSavedView.count }.by(-1)
        end

        it 'removes the specific subscription' do
          resolve_mutation(id: saved_view.to_global_id)

          expect(WorkItems::SavedViews::UserSavedView.find_by(id: user_saved_view.id)).to be_nil
        end
      end

      context 'when not subscribed to the saved view' do
        it 'returns the saved view successfully' do
          result = resolve_mutation(id: saved_view.to_global_id)

          expect(result[:saved_view]).to eq(saved_view)
        end

        it 'does not change the user saved view count' do
          expect { resolve_mutation(id: saved_view.to_global_id) }
            .not_to change { WorkItems::SavedViews::UserSavedView.count }
        end
      end
    end
  end
end
