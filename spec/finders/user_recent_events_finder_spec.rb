# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserRecentEventsFinder do
  let_it_be(:project_owner, reload: true) { create(:user) }
  let_it_be(:current_user, reload: true)  { create(:user) }
  let_it_be(:private_project)  { create(:project, :private, creator: project_owner) }
  let_it_be(:internal_project) { create(:project, :internal, creator: project_owner) }
  let_it_be(:public_project)   { create(:project, :public, creator: project_owner) }
  let!(:private_event)   { create(:event, project: private_project, author: project_owner) }
  let!(:internal_event)  { create(:event, project: internal_project, author: project_owner) }
  let!(:public_event)    { create(:event, project: public_project, author: project_owner) }
  let_it_be(:issue) { create(:issue, project: public_project) }

  let(:limit) { nil }
  let(:params) { { limit: limit } }

  subject(:finder) { described_class.new(current_user, project_owner, nil, params) }

  describe '#execute' do
    context 'when profile is public' do
      it 'returns all the events' do
        expect(finder.execute).to include(private_event, internal_event, public_event)
      end
    end

    context 'when profile is private' do
      it 'returns no event' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, project_owner).and_return(false)

        expect(finder.execute).to be_empty
      end
    end

    it 'does not include the events if the user cannot read cross project' do
      allow(Ability).to receive(:allowed?).and_call_original
      expect(Ability).to receive(:allowed?).with(current_user, :read_cross_project) { false }

      expect(finder.execute).to be_empty
    end

    context 'events from multiple users' do
      let_it_be(:second_user, reload: true) { create(:user) }
      let_it_be(:private_project_second_user) { create(:project, :private, creator: second_user) }

      let(:internal_project_second_user) { create(:project, :internal, creator: second_user) }
      let(:public_project_second_user)   { create(:project, :public, creator: second_user) }
      let!(:private_event_second_user)   { create(:event, project: private_project_second_user, author: second_user) }
      let!(:internal_event_second_user)  { create(:event, project: internal_project_second_user, author: second_user) }
      let!(:public_event_second_user)    { create(:event, project: public_project_second_user, author: second_user) }

      it 'includes events from all users', :aggregate_failures do
        events = described_class.new(current_user, [project_owner, second_user], nil, params).execute

        expect(events).to include(private_event, internal_event, public_event)
        expect(events).to include(private_event_second_user, internal_event_second_user, public_event_second_user)
        expect(events.size).to eq(6)
      end

      it 'does not include events from users with private profile', :aggregate_failures do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(current_user, :read_user_profile, second_user).and_return(false)

        events = described_class.new(current_user, [project_owner, second_user], nil, params).execute

        expect(events).to include(private_event, internal_event, public_event)
        expect(events.size).to eq(3)
      end
    end

    context 'filter activity events' do
      let!(:push_event) { create(:push_event, project: public_project, author: project_owner) }
      let!(:merge_event) { create(:event, :merged, project: public_project, author: project_owner) }
      let!(:issue_event) { create(:event, :closed, project: public_project, target: issue, author: project_owner) }
      let!(:comment_event) { create(:event, :commented, project: public_project, author: project_owner) }
      let!(:wiki_event) { create(:wiki_page_event, project: public_project, author: project_owner) }
      let!(:design_event) { create(:design_event, project: public_project, author: project_owner) }
      let!(:team_event) { create(:event, :joined, project: public_project, author: project_owner) }

      it 'includes all events', :aggregate_failures do
        event_filter = EventFilter.new(EventFilter::ALL)
        events = described_class.new(current_user, project_owner, event_filter, params).execute

        expect(events).to include(private_event, internal_event, public_event)
        expect(events).to include(push_event, merge_event, issue_event, comment_event, wiki_event, design_event, team_event)
        expect(events.size).to eq(10)
      end

      it 'only includes push events', :aggregate_failures do
        event_filter = EventFilter.new(EventFilter::PUSH)
        events = described_class.new(current_user, project_owner, event_filter, params).execute

        expect(events).to include(push_event)
        expect(events.size).to eq(1)
      end

      it 'only includes merge events', :aggregate_failures do
        event_filter = EventFilter.new(EventFilter::MERGED)
        events = described_class.new(current_user, project_owner, event_filter, params).execute

        expect(events).to include(merge_event)
        expect(events.size).to eq(1)
      end

      it 'only includes issue events', :aggregate_failures do
        event_filter = EventFilter.new(EventFilter::ISSUE)
        events = described_class.new(current_user, project_owner, event_filter, params).execute

        expect(events).to include(issue_event)
        expect(events.size).to eq(1)
      end

      it 'only includes comments events', :aggregate_failures do
        event_filter = EventFilter.new(EventFilter::COMMENTS)
        events = described_class.new(current_user, project_owner, event_filter, params).execute

        expect(events).to include(comment_event)
        expect(events.size).to eq(1)
      end

      it 'only includes wiki events', :aggregate_failures do
        event_filter = EventFilter.new(EventFilter::WIKI)
        events = described_class.new(current_user, project_owner, event_filter, params).execute

        expect(events).to include(wiki_event)
        expect(events.size).to eq(1)
      end

      it 'only includes design events', :aggregate_failures do
        event_filter = EventFilter.new(EventFilter::DESIGNS)
        events = described_class.new(current_user, project_owner, event_filter, params).execute

        expect(events).to include(design_event)
        expect(events.size).to eq(1)
      end

      it 'only includes team events', :aggregate_failures do
        event_filter = EventFilter.new(EventFilter::TEAM)
        events = described_class.new(current_user, project_owner, event_filter, params).execute

        expect(events).to include(private_event, internal_event, public_event, team_event)
        expect(events.size).to eq(4)
      end
    end

    describe 'issue activity events' do
      let(:issue) { create(:issue, project: public_project) }
      let(:note) { create(:note_on_issue, noteable: issue, project: public_project) }
      let!(:event_a) { create(:event, :commented, target: note, author: project_owner) }
      let!(:event_b) { create(:event, :closed, target: issue, author: project_owner) }

      it 'includes all issue related events', :aggregate_failures do
        events = finder.execute

        expect(events).to include(event_a)
        expect(events).to include(event_b)
      end
    end

    context 'limits' do
      before do
        stub_const("#{described_class}::DEFAULT_LIMIT", 1)
        stub_const("#{described_class}::MAX_LIMIT", 3)
      end

      context 'when limit is not set' do
        it 'returns events limited to DEFAULT_LIMIT' do
          expect(finder.execute.size).to eq(described_class::DEFAULT_LIMIT)
        end
      end

      context 'when limit is set' do
        let(:limit) { 2 }

        it 'returns events limited to specified limit' do
          expect(finder.execute.size).to eq(limit)
        end
      end

      context 'when limit is set to a number that exceeds maximum limit' do
        let(:limit) { 4 }

        before do
          create(:event, project: public_project, author: project_owner)
        end

        it 'returns events limited to MAX_LIMIT' do
          expect(finder.execute.size).to eq(described_class::MAX_LIMIT)
        end
      end
    end
  end
end
