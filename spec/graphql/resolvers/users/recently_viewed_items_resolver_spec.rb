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
    let_it_be(:wiki_page_meta) { create(:wiki_page_meta) }

    let(:work_item_service) { instance_double(Gitlab::Search::RecentWorkItems) }
    let(:mr_service) { instance_double(Gitlab::Search::RecentMergeRequests) }
    let(:wiki_service) { instance_double(Gitlab::Search::RecentWikiPages) }

    before do
      stub_feature_flags(work_items_autocomplete: true)
      allow(Gitlab::Search::RecentWorkItems).to receive(:new).with(user: user).and_return(work_item_service)
      allow(Gitlab::Search::RecentMergeRequests).to receive(:new).with(user: user).and_return(mr_service)
      allow(Gitlab::Search::RecentWikiPages).to receive(:new).with(user: user).and_return(wiki_service)
      allow(Ability).to receive(:allowed?).with(user, :read_work_item, anything).and_return(true)
      allow(Ability).to receive(:allowed?).with(user, :read_issue, anything).and_return(true)
      allow(Ability).to receive(:allowed?).with(user, :read_merge_request, anything).and_return(true)
      allow(Ability).to receive(:allowed?).with(user, :read_wiki, anything).and_return(true)
    end

    it 'combines results from all available service types', :aggregate_failures do
      allow(work_item_service).to receive(:latest_with_timestamps).and_return({
        issue => 2.hours.ago
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({
        merge_request => 1.hour.ago
      })
      allow(wiki_service).to receive(:latest_with_timestamps).and_return({
        wiki_page_meta => 30.minutes.ago
      })

      results = resolve_recent_items(current_user: user)

      expect(results).to have_attributes(size: 3)
      expect(results.map(&:item)).to contain_exactly(issue, merge_request, wiki_page_meta)
    end

    it 'sorts items by timestamp across all types (most recent first)' do
      allow(work_item_service).to receive(:latest_with_timestamps).and_return({
        issue => 3.hours.ago
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({
        merge_request => 1.hour.ago
      })
      allow(wiki_service).to receive(:latest_with_timestamps).and_return({
        wiki_page_meta => 30.minutes.ago
      })

      results = resolve_recent_items(current_user: user)

      expect(results.map(&:item)).to eq([wiki_page_meta, merge_request, issue])
    end

    it 'filters out wiki pages the user cannot read' do
      allow(work_item_service).to receive(:latest_with_timestamps).and_return({})
      allow(mr_service).to receive(:latest_with_timestamps).and_return({})
      allow(wiki_service).to receive(:latest_with_timestamps).and_return({
        wiki_page_meta => 30.minutes.ago
      })

      allow(Ability).to receive(:allowed?).with(user, :read_wiki, wiki_page_meta).and_return(false)

      results = resolve_recent_items(current_user: user)

      expect(results).to be_empty
    end

    it 'returns RecentlyViewedItem structs with correct data' do
      timestamp = 1.hour.ago
      allow(work_item_service).to receive(:latest_with_timestamps).and_return({
        issue => timestamp
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({})
      allow(wiki_service).to receive(:latest_with_timestamps).and_return({})

      results = resolve_recent_items(current_user: user)

      expect(results.first).to have_attributes(
        item: issue,
        viewed_at: timestamp
      )
    end

    it 'returns empty array when no services return items' do
      allow(work_item_service).to receive(:latest_with_timestamps).and_return({})
      allow(mr_service).to receive(:latest_with_timestamps).and_return({})
      allow(wiki_service).to receive(:latest_with_timestamps).and_return({})

      results = resolve_recent_items(current_user: user)

      expect(results).to be_empty
    end

    it 'filters out items the user cannot read (e.g., SAML authorization failure)', :aggregate_failures do
      allow(work_item_service).to receive(:latest_with_timestamps).and_return({
        issue => 2.hours.ago
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({
        merge_request => 1.hour.ago
      })
      allow(wiki_service).to receive(:latest_with_timestamps).and_return({
        wiki_page_meta => 30.minutes.ago
      })

      # Simulate SAML authorization failure: user can no longer read the work item
      allow(Ability).to receive(:allowed?).with(user, :read_work_item, issue).and_return(false)
      allow(Ability).to receive(:allowed?).with(user, :read_issue, issue).and_return(false)
      allow(Ability).to receive(:allowed?).with(user, :read_merge_request, merge_request).and_return(true)
      allow(Ability).to receive(:allowed?).with(user, :read_wiki, wiki_page_meta).and_return(true)

      results = resolve_recent_items(current_user: user)

      # Should return merge request and wiki page, work item should be filtered out
      expect(results).to have_attributes(size: 2)
      expect(results.map(&:item)).to contain_exactly(merge_request, wiki_page_meta)
    end

    it 'returns empty array when user cannot read any items' do
      allow(work_item_service).to receive(:latest_with_timestamps).and_return({
        issue => 2.hours.ago
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({
        merge_request => 1.hour.ago
      })
      allow(wiki_service).to receive(:latest_with_timestamps).and_return({
        wiki_page_meta => 30.minutes.ago
      })

      # Simulate SAML authorization failure: user can no longer read any items
      allow(Ability).to receive(:allowed?).with(user, :read_work_item, issue).and_return(false)
      allow(Ability).to receive(:allowed?).with(user, :read_issue, issue).and_return(false)
      allow(Ability).to receive(:allowed?).with(user, :read_merge_request, merge_request).and_return(false)
      allow(Ability).to receive(:allowed?).with(user, :read_wiki, wiki_page_meta).and_return(false)

      results = resolve_recent_items(current_user: user)

      expect(results).to be_empty
    end

    it 'filters out unknown item types' do
      # Use a real class that's not WorkItem, MergeRequest, or WikiPage::Meta to test the else clause
      unknown_item = create(:todo)

      allow(work_item_service).to receive(:latest_with_timestamps).and_return({
        unknown_item => 1.hour.ago
      })
      allow(mr_service).to receive(:latest_with_timestamps).and_return({})
      allow(wiki_service).to receive(:latest_with_timestamps).and_return({})

      results = resolve_recent_items(current_user: user)

      # Unknown item type should be filtered out (returns false in else clause)
      expect(results).to be_empty
    end

    context 'when work_items_autocomplete is disabled' do
      let(:issue_service) { instance_double(Gitlab::Search::RecentIssues) }

      before do
        stub_feature_flags(work_items_autocomplete: false)
        allow(Gitlab::Search::RecentIssues).to receive(:new).with(user: user).and_return(issue_service)
        allow(Ability).to receive(:allowed?).with(user, :read_issue, anything).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_merge_request, anything).and_return(true)
        allow(Ability).to receive(:allowed?).with(user, :read_wiki, anything).and_return(true)
        allow(issue_service).to receive(:latest_with_timestamps).and_return({})
        allow(mr_service).to receive(:latest_with_timestamps).and_return({})
        allow(wiki_service).to receive(:latest_with_timestamps).and_return({})
      end

      it 'uses RecentIssues instead of RecentWorkItems', :aggregate_failures do
        expect(Gitlab::Search::RecentIssues).to receive(:new).with(user: user).and_return(issue_service)
        expect(Gitlab::Search::RecentWorkItems).not_to receive(:new)
        resolve_recent_items(current_user: user)
      end
    end
  end

  def resolve_recent_items(current_user:)
    resolve(described_class, obj: current_user, ctx: { current_user: current_user })
  end
end
