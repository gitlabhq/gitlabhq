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
end
