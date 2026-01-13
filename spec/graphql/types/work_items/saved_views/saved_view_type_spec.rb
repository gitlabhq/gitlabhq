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

  describe '#filters' do
    it 'returns an empty hash' do
      expect(resolve_field(:filters, saved_view, current_user: current_user)).to eq({})
    end
  end

  describe '#filter_warnings' do
    it 'returns an empty array' do
      expect(resolve_field(:filter_warnings, saved_view, current_user: current_user)).to eq([])
    end
  end

  describe '#subscribed' do
    it 'returns false' do
      saved_view = create(:saved_view)

      expect(resolve_field(:subscribed, saved_view, current_user: current_user)).to be false
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

        expect(url).to eq(Gitlab::Routing.url_helpers.subscribe_group_saved_view_url(group, saved_view.id))
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

        expect(url).to eq(Gitlab::Routing.url_helpers.subscribe_project_saved_view_url(project, saved_view.id))
      end
    end
  end
end
