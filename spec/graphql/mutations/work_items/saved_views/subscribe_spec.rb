# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::WorkItems::SavedViews::Subscribe, feature_category: :planning_views do
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
      let_it_be(:guest_user) { create(:user) }
      let(:current_ctx) { { current_user: guest_user } }

      before_all do
        project.add_guest(guest_user)
      end

      it 'allows subscription to the saved view' do
        result = resolve_mutation(id: saved_view.to_global_id)

        expect(result[:saved_view]).to eq(saved_view)
        expect(result[:errors]).to be_empty
      end

      it 'creates a user saved view record' do
        expect { resolve_mutation(id: saved_view.to_global_id) }
          .to change { WorkItems::SavedViews::UserSavedView.count }.by(1)
      end
    end

    context 'when the user has permission' do
      it 'successfully subscribes to the saved view' do
        result = resolve_mutation(id: saved_view.to_global_id)

        expect(result[:saved_view]).to eq(saved_view)
        expect(result[:errors]).to be_empty
      end

      it 'tracks the saved_view_subscribe internal event', :clean_gitlab_redis_shared_state do
        expect { resolve_mutation(id: saved_view.to_global_id) }
          .to trigger_internal_events('saved_view_subscribe')
          .with(
            category: 'Gitlab::WorkItems::Instrumentation::TrackingService',
            user: current_user,
            namespace: saved_view.namespace,
            project: project,
            additional_properties: { property: 'Planner' }
          )
          .and increment_usage_metrics(
            'redis_hll_counters.count_distinct_user_id_from_saved_view_subscribe_weekly',
            'redis_hll_counters.count_distinct_user_id_from_saved_view_subscribe_monthly'
          )
      end

      it 'creates a user saved view record' do
        expect { resolve_mutation(id: saved_view.to_global_id) }
          .to change { WorkItems::SavedViews::UserSavedView.count }.by(1)
      end

      it 'sets the correct attributes on the user saved view' do
        resolve_mutation(id: saved_view.to_global_id)

        user_saved_view = WorkItems::SavedViews::UserSavedView.last

        expect(user_saved_view.user).to eq(current_user)
        expect(user_saved_view.saved_view).to eq(saved_view)
        expect(user_saved_view.namespace).to eq(project.project_namespace)
      end

      it 'sets the initial relative position' do
        resolve_mutation(id: saved_view.to_global_id)

        user_saved_view = WorkItems::SavedViews::UserSavedView.last

        expect(user_saved_view.relative_position).not_to be_nil
      end

      context 'when already subscribed' do
        before do
          create(:user_saved_view, user: current_user, saved_view: saved_view, namespace: project.project_namespace)
        end

        it 'does not create a duplicate subscription' do
          expect { resolve_mutation(id: saved_view.to_global_id) }
            .not_to change { WorkItems::SavedViews::UserSavedView.count }
        end

        it 'returns the saved view successfully' do
          result = resolve_mutation(id: saved_view.to_global_id)

          expect(result[:saved_view]).to eq(saved_view)
          expect(result[:errors]).to be_empty
        end

        # Unlike the unsubscribe path, a redundant subscribe is intentionally still tracked.
        it 'still tracks the saved_view_subscribe event' do
          expect { resolve_mutation(id: saved_view.to_global_id) }
            .to trigger_internal_events('saved_view_subscribe')
            .with(
              category: 'Gitlab::WorkItems::Instrumentation::TrackingService',
              user: current_user,
              namespace: saved_view.namespace,
              project: project,
              additional_properties: { property: 'Planner' }
            )
        end
      end

      context 'when the subscription limit is reached' do
        before do
          stub_licensed_features(increased_saved_views_limit: false)

          namespace = project.project_namespace
          limit = WorkItems::SavedViews::UserSavedView.user_saved_view_limit(namespace)
          create_list(:saved_view, limit, namespace: namespace).each do |sv|
            create(:user_saved_view, user: current_user, saved_view: sv, namespace: namespace)
          end
        end

        it 'returns an error' do
          result = resolve_mutation(id: saved_view.to_global_id)

          expect(result[:saved_view]).to be_nil
          expect(result[:errors]).to eq(['Subscribed saved view limit exceeded.'])
        end

        it 'does not create a new subscription' do
          expect { resolve_mutation(id: saved_view.to_global_id) }
            .not_to change { WorkItems::SavedViews::UserSavedView.count }
        end

        it 'does not track the saved_view_subscribe event' do
          expect { resolve_mutation(id: saved_view.to_global_id) }
            .not_to trigger_internal_events('saved_view_subscribe')
        end
      end
    end
  end
end
