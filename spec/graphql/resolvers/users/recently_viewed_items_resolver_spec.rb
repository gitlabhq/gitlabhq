# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::RecentlyViewedItemsResolver, feature_category: :user_profile do
  include GraphqlHelpers

  specify { expect(described_class).to have_nullable_graphql_type(Types::Users::RecentlyViewedItemType) }
  specify { expect(described_class).to require_graphql_authorizations(:read_user) }

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue) }
    let_it_be(:merge_request) { create(:merge_request) }

    let(:issue_service) { instance_double(Gitlab::Search::RecentIssues) }
    let(:mr_service) { instance_double(Gitlab::Search::RecentMergeRequests) }

    before do
      allow(Gitlab::Search::RecentIssues).to receive(:new).with(user: user).and_return(issue_service)
      allow(Gitlab::Search::RecentMergeRequests).to receive(:new).with(user: user).and_return(mr_service)
    end

    it 'combines results from all available service types' do
      allow(issue_service).to receive(:latest_with_timestamps).and_return({
        issue => 2.hours.ago
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({
        merge_request => 1.hour.ago
      })

      results = resolve_recent_items(current_user: user)

      expect(results).to have_attributes(size: 2)
      expect(results.map(&:item)).to contain_exactly(issue, merge_request)
    end

    it 'sorts items by timestamp across all types (most recent first)' do
      allow(issue_service).to receive(:latest_with_timestamps).and_return({
        issue => 3.hours.ago
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({
        merge_request => 1.hour.ago
      })

      results = resolve_recent_items(current_user: user)

      expect(results.map(&:item)).to eq([merge_request, issue])
    end

    it 'returns RecentlyViewedItem structs with correct data' do
      timestamp = 1.hour.ago
      allow(issue_service).to receive(:latest_with_timestamps).and_return({
        issue => timestamp
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({})

      results = resolve_recent_items(current_user: user)

      expect(results.first).to have_attributes(
        item: issue,
        viewed_at: timestamp
      )
    end

    it 'returns empty array when no services return items' do
      allow(issue_service).to receive(:latest_with_timestamps).and_return({})
      allow(mr_service).to receive(:latest_with_timestamps).and_return({})

      results = resolve_recent_items(current_user: user)

      expect(results).to be_empty
    end
  end

  def resolve_recent_items(current_user:)
    resolve(described_class, obj: current_user, ctx: { current_user: current_user })
  end
end
