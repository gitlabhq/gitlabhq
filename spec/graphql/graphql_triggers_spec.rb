# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphqlTriggers do
  describe '.issuable_assignees_updated' do
    it 'triggers the issuableAssigneesUpdated subscription' do
      assignees = create_list(:user, 2)
      issue = create(:issue, assignees: assignees)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'issuableAssigneesUpdated',
        { issuable_id: issue.to_gid },
        issue
      )

      GraphqlTriggers.issuable_assignees_updated(issue)
    end
  end

  describe '.issuable_title_updated' do
    it 'triggers the issuableTitleUpdated subscription' do
      work_item = create(:work_item)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'issuableTitleUpdated',
        { issuable_id: work_item.to_gid },
        work_item
      ).and_call_original

      GraphqlTriggers.issuable_title_updated(work_item)
    end
  end
end
