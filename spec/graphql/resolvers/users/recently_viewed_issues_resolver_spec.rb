# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::RecentlyViewedIssuesResolver, feature_category: :user_profile do
  include GraphqlHelpers

  specify { expect(described_class).to have_nullable_graphql_type(Types::IssueType) }

  specify { expect(described_class).to require_graphql_authorizations(:read_user) }

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:membership) { create(:project_member, project: project, user: user) }
    let_it_be(:recently_viewed_issue1) { create(:issue, project: project, author: user) }
    let_it_be(:recently_viewed_issue2) { create(:issue, project: project, author: user) }
    let_it_be(:unviewed_issue) { create(:issue, project: project, author: user) }
    let_it_be(:finder) { ::Gitlab::Search::RecentIssues.new(user: user) }

    before do
      finder.log_view(recently_viewed_issue1)
      finder.log_view(recently_viewed_issue2)
    end

    it 'returns recently viewed items for the current user' do
      resolved_issues = resolve_recent_issues(current_user: user)
      expect(resolved_issues).to contain_exactly(recently_viewed_issue1, recently_viewed_issue2)
      expect(resolved_issues).not_to include(unviewed_issue)
    end

    it 'does not return recently viewed items for another user' do
      resolved_issues = resolve_recent_issues(current_user: other_user)
      expect(resolved_issues).not_to include(recently_viewed_issue1, recently_viewed_issue2)
    end

    it 'does not leak items you no longer have access to' do
      # revoke access
      membership.destroy!

      resolved_issues = resolve_recent_issues(current_user: user)
      expect(resolved_issues).not_to include(recently_viewed_issue1, recently_viewed_issue2)
    end
  end

  def resolve_recent_issues(current_user:)
    resolve(described_class, obj: current_user, ctx: { current_user: current_user })
  end
end
