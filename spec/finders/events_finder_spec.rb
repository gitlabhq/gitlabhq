# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventsFinder do
  let_it_be(:user) { create(:user) }
  let(:private_user) { create(:user, private_profile: true) }
  let(:other_user) { create(:user) }

  let(:project1) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }
  let(:project2) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }

  let(:closed_issue) { create(:closed_issue, project: project1, author: user) }
  let(:opened_merge_request) { create(:merge_request, source_project: project2, author: user) }
  let!(:closed_issue_event) { create(:event, :closed, project: project1, author: user, target: closed_issue, created_at: Date.new(2016, 12, 30)) }
  let!(:opened_merge_request_event) { create(:event, :created, project: project2, author: user, target: opened_merge_request, created_at: Date.new(2017, 1, 31)) }
  let(:closed_issue2) { create(:closed_issue, project: project1, author: user) }
  let(:opened_merge_request2) { create(:merge_request, source_project: project2, author: user) }
  let!(:closed_issue_event2) { create(:event, :closed, project: project1, author: user, target: closed_issue, created_at: Date.new(2016, 2, 2)) }
  let!(:opened_merge_request_event2) { create(:event, :created, project: project2, author: user, target: opened_merge_request, created_at: Date.new(2017, 2, 2)) }
  let(:opened_merge_request3) { create(:merge_request, source_project: project1, author: other_user) }
  let!(:other_developer_event) { create(:event, :created, project: project1, author: other_user, target: opened_merge_request3 ) }

  let_it_be(:public_project) { create(:project, :public, creator_id: user.id, namespace: user.namespace) }

  let(:confidential_issue) { create(:closed_issue, confidential: true, project: public_project, author: user) }
  let!(:confidential_event) { create(:event, :closed, project: public_project, author: user, target: confidential_issue) }

  context 'when targeting a user' do
    it 'returns events between specified dates filtered on action and type' do
      events = described_class.new(source: user, current_user: user, action: 'created', target_type: 'merge_request', after: Date.new(2017, 1, 1), before: Date.new(2017, 2, 1)).execute

      expect(events).to eq([opened_merge_request_event])
    end

    it 'does not return events the current_user does not have access to' do
      events = described_class.new(source: user, current_user: other_user).execute

      expect(events).not_to include(opened_merge_request_event)
    end

    it 'does not include events on confidential issues the user does not have access to' do
      events = described_class.new(source: user, current_user: other_user).execute

      expect(events).not_to include(confidential_event)
    end

    it 'includes confidential events user has access to' do
      public_project.add_developer(other_user)
      events = described_class.new(source: user, current_user: other_user).execute

      expect(events).to include(confidential_event)
    end

    it 'returns nothing when the current user cannot read cross project' do
      expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }

      events = described_class.new(source: user, current_user: user).execute

      expect(events).to be_empty
    end

    it 'returns nothing when the target profile is private' do
      events = described_class.new(source: private_user, current_user: other_user).execute

      expect(events).to be_empty
    end
  end

  describe 'wiki events' do
    let_it_be(:events) { create_list(:wiki_page_event, 3, project: public_project) }

    subject(:finder) { described_class.new(source: public_project, target_type: 'wiki', current_user: user) }

    it 'can find the wiki events' do
      expect(finder.execute).to match_array(events)
    end
  end

  context 'dashboard events' do
    before do
      project1.add_developer(other_user)
    end

    context 'scope is `all`' do
      it 'includes activity of other users' do
        events = described_class.new(source: user, current_user: user, scope: 'all').execute

        expect(events).to include(other_developer_event)
      end
    end

    context 'scope is not `all`' do
      it 'does not include activity of other users' do
        events = described_class.new(source: user, current_user: user, scope: '').execute

        expect(events).not_to include(other_developer_event)
      end
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
