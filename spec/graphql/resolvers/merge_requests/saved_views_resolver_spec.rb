# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequests::SavedViewsResolver, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:view_a) { create(:merge_request_saved_view, user: current_user, name: 'View A') }
  let_it_be(:view_b) { create(:merge_request_saved_view, user: current_user, name: 'View B') }
  let_it_be(:other_view) { create(:merge_request_saved_view, user: other_user) }

  specify do
    expect(described_class.type).to eq(Types::MergeRequests::SavedViewType.connection_type)
  end

  describe '#resolve' do
    it 'returns only the current user views, ordered by id ascending', :aggregate_failures do
      result = Gitlab::Graphql::Lazy.force(resolve(described_class, ctx: { current_user: current_user })).to_a

      expect(result.map(&:name)).to eq(['View A', 'View B'])
      expect(result).not_to include(other_view)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(mr_dashboard_saved_views: false)
      end

      it 'returns empty' do
        result = Gitlab::Graphql::Lazy.force(resolve(described_class, ctx: { current_user: current_user })).to_a

        expect(result).to eq([])
      end
    end
  end
end
