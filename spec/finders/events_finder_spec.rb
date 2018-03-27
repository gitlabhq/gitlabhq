require 'spec_helper'

describe EventsFinder do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:project1) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }
  let(:project2) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }
  let(:closed_issue) { create(:closed_issue, project: project1, author: user) }
  let(:opened_merge_request) { create(:merge_request, source_project: project2, author: user) }
  let!(:closed_issue_event) { create(:event, project: project1, author: user, target: closed_issue, action: Event::CLOSED, created_at: Date.new(2016, 12, 30)) }
  let!(:opened_merge_request_event) { create(:event, project: project2, author: user, target: opened_merge_request, action: Event::CREATED, created_at: Date.new(2017, 1, 31)) }
  let(:closed_issue2) { create(:closed_issue, project: project1, author: user) }
  let(:opened_merge_request2) { create(:merge_request, source_project: project2, author: user) }
  let!(:closed_issue_event2) { create(:event, project: project1, author: user, target: closed_issue, action: Event::CLOSED, created_at: Date.new(2016, 2, 2)) }
  let!(:opened_merge_request_event2) { create(:event, project: project2, author: user, target: opened_merge_request, action: Event::CREATED, created_at: Date.new(2017, 2, 2)) }

  context 'when targeting a user' do
    it 'returns events between specified dates filtered on action and type' do
      events = described_class.new(source: user, current_user: user, action: 'created', target_type: 'merge_request', after: Date.new(2017, 1, 1), before: Date.new(2017, 2, 1)).execute

      expect(events).to eq([opened_merge_request_event])
    end

    it 'does not return events the current_user does not have access to' do
      events = described_class.new(source: user, current_user: other_user).execute

      expect(events).not_to include(opened_merge_request_event)
    end

    it 'returns nothing when the current user cannot read cross project' do
      expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

      events = described_class.new(source: user, current_user: user).execute

      expect(events).to be_empty
    end
  end

  context 'when targeting a project' do
    it 'returns project events between specified dates filtered on action and type' do
      events = described_class.new(source: project1, current_user: user, action: 'closed', target_type: 'issue', after: Date.new(2016, 12, 1), before: Date.new(2017, 1, 1)).execute

      expect(events).to eq([closed_issue_event])
    end

    it 'does not return events the current_user does not have access to' do
      events = described_class.new(source: project2, current_user: other_user).execute

      expect(events).to be_empty
    end
  end
end
