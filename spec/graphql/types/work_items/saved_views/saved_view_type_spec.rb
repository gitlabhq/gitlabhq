# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::SavedViews::SavedViewType, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, planners: [current_user]) }

  let_it_be(:filter_data) { { state: 'opened', confidential: true } }
  let_it_be(:display_settings) { { 'hiddenMetadataKeys' => ['assignee'] } }

  let_it_be(:saved_view) do
    create(:saved_view, namespace: group, filter_data: filter_data, display_settings: display_settings,
      sort: :priority_asc)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_saved_view) }

  describe 'field call count limits' do
    it 'limits filters field to 1 call' do
      extension = described_class.fields['filters'].extensions.find do |ext|
        ext.is_a?(Gitlab::Graphql::Limit::FieldCallCount)
      end

      expect(extension).to be_present
      expect(extension.options[:limit]).to eq(1)
    end

    it 'limits filterWarnings field to 1 call' do
      extension = described_class.fields['filterWarnings'].extensions.find do |ext|
        ext.is_a?(Gitlab::Graphql::Limit::FieldCallCount)
      end

      expect(extension).to be_present
      expect(extension.options[:limit]).to eq(1)
    end

    it 'limits workItems field to 1 call' do
      extension = described_class.fields['workItems'].extensions.find do |ext|
        ext.is_a?(Gitlab::Graphql::Limit::FieldCallCount)
      end

      expect(extension).to be_present
      expect(extension.options[:limit]).to eq(1)
    end
  end

  describe '#filters' do
    it 'returns validated filters from filter_data' do
      expect(resolve_field(:filters, saved_view, current_user: current_user)).to eq({
        'state' => 'opened',
        'confidential' => true
      })
    end

    context 'with assignee filter' do
      let_it_be(:assignee) { create(:user) }
      let_it_be(:saved_view_with_assignee) do
        create(:saved_view, namespace: group, filter_data: { assignee_ids: [assignee.id] })
      end

      it 'returns assignee_usernames' do
        filters = resolve_field(:filters, saved_view_with_assignee, current_user: current_user)

        expect(filters['assigneeUsernames']).to eq([assignee.username])
      end
    end

    context 'with deleted assignee' do
      let_it_be(:deleted_user_id) { non_existing_record_id }
      let_it_be(:saved_view_with_deleted_assignee) do
        create(:saved_view, namespace: group, filter_data: { assignee_ids: [deleted_user_id] })
      end

      it 'returns empty filters' do
        filters = resolve_field(:filters, saved_view_with_deleted_assignee, current_user: current_user)

        expect(filters['assigneeUsernames']).to be_nil
      end
    end

    context 'when FilterSanitizerService fails' do
      let_it_be(:saved_view_with_data) do
        create(:saved_view, namespace: group, filter_data: { state: 'opened' })
      end

      before do
        allow_next_instance_of(::WorkItems::SavedViews::FilterSanitizerService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'Invalid filter format')
          )
        end
      end

      it 'returns empty filters and base error in filter_warnings' do
        filters = resolve_field(:filters, saved_view_with_data, current_user: current_user)
        warnings = resolve_field(:filter_warnings, saved_view_with_data, current_user: current_user)

        expect(filters).to eq({})
        expect(warnings).to contain_exactly(
          { field: :base, message: 'Invalid filter format' }
        )
      end
    end
  end

  describe '#filter_warnings' do
    it 'returns empty array when all filters are valid' do
      expect(resolve_field(:filter_warnings, saved_view, current_user: current_user)).to eq([])
    end

    context 'with deleted assignee' do
      let_it_be(:deleted_user_id) { non_existing_record_id }
      let_it_be(:saved_view_with_deleted_assignee) do
        create(:saved_view, namespace: group, filter_data: { assignee_ids: [deleted_user_id] })
      end

      it 'returns warning for missing assignee' do
        warnings = resolve_field(:filter_warnings, saved_view_with_deleted_assignee, current_user: current_user)

        expect(warnings).to contain_exactly(
          { field: :assignee_usernames, message: '1 assignee(s) not found' }
        )
      end
    end

    context 'with multiple deleted records' do
      let_it_be(:existing_user) { create(:user) }
      let_it_be(:deleted_user_id) { non_existing_record_id }
      let_it_be(:deleted_label_id) { non_existing_record_id }
      let_it_be(:multi_filter_saved_view) do
        create(:saved_view, namespace: group, filter_data: {
          assignee_ids: [existing_user.id, deleted_user_id],
          label_ids: [deleted_label_id]
        })
      end

      it 'returns warnings for all missing records' do
        warnings = resolve_field(:filter_warnings, multi_filter_saved_view, current_user: current_user)

        expect(warnings).to contain_exactly(
          { field: :assignee_usernames, message: '1 assignee(s) not found' },
          { field: :label_name, message: '1 label(s) not found' }
        )
      end
    end
  end

  describe '#subscribed' do
    context 'when user is not subscribed' do
      it 'returns false', :request_store do
        result = resolve_field(:subscribed, saved_view, current_user: current_user)

        expect(sync(result)).to be false
      end
    end

    context 'when user is subscribed' do
      before do
        create(:user_saved_view, user: current_user, saved_view: saved_view, namespace: group)
      end

      it 'returns true', :request_store do
        result = resolve_field(:subscribed, saved_view, current_user: current_user)

        expect(sync(result)).to be true
      end
    end

    context 'when batch loading multiple saved views', :request_store do
      let_it_be(:saved_view2) { create(:saved_view, namespace: group) }
      let_it_be(:saved_view3) { create(:saved_view, namespace: group) }

      before do
        create(:user_saved_view, user: current_user, saved_view: saved_view, namespace: group)
        create(:user_saved_view, user: current_user, saved_view: saved_view3, namespace: group)
      end

      it 'does not cause N+1 queries' do
        single_view = [saved_view]
        all_views = [saved_view, saved_view2, saved_view3]

        control = ActiveRecord::QueryRecorder.new do
          results = single_view.map { |view| resolve_field(:subscribed, view, current_user: current_user) }
          sync(results)
        end

        expect do
          results = all_views.map { |view| resolve_field(:subscribed, view, current_user: current_user) }
          synced = sync(results)
          expect(synced).to match_array([true, false, true])
        end.not_to exceed_query_limit(control)
      end
    end
  end

  describe '#sort' do
    it 'returns the saved view sorting option' do
      expect(resolve_field(:sort, saved_view, current_user: current_user)).to eq(:priority_asc)
    end

    context 'when sort is nil' do
      let_it_be(:saved_view_without_sort) do
        create(:saved_view, namespace: group, filter_data: filter_data, sort: nil)
      end

      it 'returns nil' do
        expect(resolve_field(:sort, saved_view_without_sort, current_user: current_user)).to be_nil
      end
    end
  end

  describe '#share_url' do
    context 'when namespace is a group' do
      it 'returns the group URL' do
        url = resolve_field(:share_url, saved_view, current_user: current_user)

        expect(url).to eq(Gitlab::Routing.url_helpers.group_saved_view_url(group, saved_view.id))
      end
    end

    context 'when namespace is a project namespace' do
      let_it_be(:project) { create(:project, planners: [current_user]) }
      let_it_be(:saved_view) { create(:saved_view, namespace: project.project_namespace) }

      before do
        project.add_planner(current_user)
      end

      it 'returns the project URL' do
        url = resolve_field(:share_url, saved_view, current_user: current_user)

        expect(url).to eq(Gitlab::Routing.url_helpers.project_saved_view_url(project, saved_view.id))
      end
    end
  end
end
