# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::RecentlyViewedMergeRequestsResolver, feature_category: :user_profile do
  include GraphqlHelpers

  specify { expect(described_class).to have_nullable_graphql_type(Types::MergeRequestType) }

  specify { expect(described_class).to require_graphql_authorizations(:read_user) }

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:membership) { create(:project_member, project: project, user: user) }
    let_it_be(:recently_viewed_merge_request1) do
      create(:merge_request, source_project: project, source_branch: 'branch-1', author: user)
    end

    let_it_be(:recently_viewed_merge_request2) do
      create(:merge_request, source_project: project, source_branch: 'branch-2', author: user)
    end

    let_it_be(:unviewed_merge_request) do
      create(:merge_request, source_project: project, source_branch: 'branch-3', author: user)
    end

    let_it_be(:finder) { ::Gitlab::Search::RecentMergeRequests.new(user: user) }

    before do
      finder.log_view(recently_viewed_merge_request1)
      finder.log_view(recently_viewed_merge_request2)
    end

    it 'returns recently viewed items for the current user' do
      resolved_merge_requests = resolve_recent_merge_requests(current_user: user)
      expect(resolved_merge_requests).to contain_exactly(recently_viewed_merge_request1, recently_viewed_merge_request2)
      expect(resolved_merge_requests).not_to include(unviewed_merge_request)
    end

    it 'does not return recently viewed items for another user' do
      resolved_merge_requests = resolve_recent_merge_requests(current_user: other_user)
      expect(resolved_merge_requests).not_to include(recently_viewed_merge_request1, recently_viewed_merge_request2)
    end

    it 'does not leak items you no longer have access to' do
      # revoke access
      membership.destroy!

      resolved_merge_requests = resolve_recent_merge_requests(current_user: user)
      expect(resolved_merge_requests).not_to include(recently_viewed_merge_request1, recently_viewed_merge_request2)
    end
  end

  def resolve_recent_merge_requests(current_user:)
    resolve(described_class, obj: current_user, ctx: { current_user: current_user })
  end
end
