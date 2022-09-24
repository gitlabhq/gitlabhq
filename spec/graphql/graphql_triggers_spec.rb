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

  describe '.issuable_description_updated' do
    it 'triggers the issuableDescriptionUpdated subscription' do
      work_item = create(:work_item)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'issuableDescriptionUpdated',
        { issuable_id: work_item.to_gid },
        work_item
      ).and_call_original

      GraphqlTriggers.issuable_description_updated(work_item)
    end
  end

  describe '.issuable_labels_updated' do
    it 'triggers the issuableLabelsUpdated subscription' do
      project = create(:project)
      labels = create_list(:label, 3, project: project)
      issue = create(:issue, labels: labels)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'issuableLabelsUpdated',
        { issuable_id: issue.to_gid },
        issue
      )

      GraphqlTriggers.issuable_labels_updated(issue)
    end
  end

  describe '.issuable_dates_updated' do
    it 'triggers the issuableDatesUpdated subscription' do
      work_item = create(:work_item)

      expect(GitlabSchema.subscriptions).to receive(:trigger).with(
        'issuableDatesUpdated',
        { issuable_id: work_item.to_gid },
        work_item
      ).and_call_original

      GraphqlTriggers.issuable_dates_updated(work_item)
    end
  end
end
