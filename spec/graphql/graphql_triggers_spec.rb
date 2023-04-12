# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlTriggers, feature_category: :shared do
  let_it_be(:issuable, refind: true) { create(:work_item) }

  describe '.issuable_assignees_updated' do
    let(:assignees) { create_list(:user, 2) }

    before do
      issuable.update!(assignees: assignees)
    end

    it 'triggers the issuable_assignees_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_assignees_updated,
        { issuable_id: issuable.to_gid },
        issuable
      )

      GraphqlTriggers.issuable_assignees_updated(issuable)
    end
  end

  describe '.issuable_title_updated' do
    it 'triggers the issuable_title_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_title_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      GraphqlTriggers.issuable_title_updated(issuable)
    end
  end

  describe '.issuable_description_updated' do
    it 'triggers the issuable_description_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_description_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      GraphqlTriggers.issuable_description_updated(issuable)
    end
  end

  describe '.issuable_labels_updated' do
    let(:labels) { create_list(:label, 3, project: create(:project)) }

    before do
      issuable.update!(labels: labels)
    end

    it 'triggers the issuable_labels_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_labels_updated,
        { issuable_id: issuable.to_gid },
        issuable
      )

      GraphqlTriggers.issuable_labels_updated(issuable)
    end
  end

  describe '.issuable_dates_updated' do
    it 'triggers the issuable_dates_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_dates_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      GraphqlTriggers.issuable_dates_updated(issuable)
    end
  end

  describe '.issuable_milestone_updated' do
    it 'triggers the issuable_milestone_updated subscription' do
      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :issuable_milestone_updated,
        { issuable_id: issuable.to_gid },
        issuable
      ).and_call_original

      GraphqlTriggers.issuable_milestone_updated(issuable)
    end
  end

  describe '.merge_request_reviewers_updated' do
    it 'triggers the merge_request_reviewers_updated subscription' do
      merge_request = build_stubbed(:merge_request)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :merge_request_reviewers_updated,
        { issuable_id: merge_request.to_gid },
        merge_request
      ).and_call_original

      GraphqlTriggers.merge_request_reviewers_updated(merge_request)
    end
  end

  describe '.merge_request_merge_status_updated' do
    it 'triggers the merge_request_merge_status_updated subscription' do
      merge_request = build_stubbed(:merge_request)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :merge_request_merge_status_updated,
        { issuable_id: merge_request.to_gid },
        merge_request
      ).and_call_original

      GraphqlTriggers.merge_request_merge_status_updated(merge_request)
    end

    context 'when realtime_mr_status_change feature flag is disabled' do
      before do
        stub_feature_flags(realtime_mr_status_change: false)
      end

      it 'does not trigger realtime_mr_status_change subscription' do
        merge_request = build_stubbed(:merge_request)

        expect(GitlabSchema.subscriptions).not_to receive(:trigger)

        GraphqlTriggers.merge_request_merge_status_updated(merge_request)
      end
    end
  end

  describe '.merge_request_approval_state_updated' do
    it 'triggers the merge_request_approval_state_updated subscription' do
      merge_request = build_stubbed(:merge_request)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        :merge_request_approval_state_updated,
        { issuable_id: merge_request.to_gid },
        merge_request
      ).and_call_original

      GraphqlTriggers.merge_request_approval_state_updated(merge_request)
    end
  end
end
