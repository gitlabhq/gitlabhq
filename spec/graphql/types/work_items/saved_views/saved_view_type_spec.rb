# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::SavedViews::SavedViewType, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  specify { expect(described_class).to require_graphql_authorizations(:read_saved_view) }

  describe '#filters' do
    it 'returns an empty hash' do
      saved_view = create(:saved_view)

      expect(resolve_field(:filters, saved_view, current_user: current_user)).to eq({})
    end
  end

  describe '#filter_warnings' do
    it 'returns an empty array' do
      saved_view = create(:saved_view)

      expect(resolve_field(:filter_warnings, saved_view, current_user: current_user)).to eq([])
    end
  end

  describe '#share_url' do
    context 'when namespace is a group' do
      let_it_be(:group) { create(:group, planners: [current_user]) }
      let_it_be(:saved_view) { create(:saved_view, namespace: group) }

      it 'returns the group subscribe URL' do
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

      it 'returns the project subscribe URL' do
        url = resolve_field(:share_url, saved_view, current_user: current_user)

        expect(url).to eq(Gitlab::Routing.url_helpers.subscribe_project_saved_view_url(project, saved_view.id))
      end
    end
  end
end
