# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserRecentEventsFinder do
  let_it_be(:project_owner, reload: true) { create(:user) }
  let_it_be(:current_user, reload: true)  { create(:user) }
  let(:private_project)  { create(:project, :private, creator: project_owner) }
  let(:internal_project) { create(:project, :internal, creator: project_owner) }
  let(:public_project)   { create(:project, :public, creator: project_owner) }
  let!(:private_event)   { create(:event, project: private_project, author: project_owner) }
  let!(:internal_event)  { create(:event, project: internal_project, author: project_owner) }
  let!(:public_event)    { create(:event, project: public_project, author: project_owner) }
  let(:limit) { nil }
  let(:params) { { limit: limit } }

  subject(:finder) { described_class.new(current_user, project_owner, params) }

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

    describe 'design activity events' do
      let_it_be(:event_a) { create(:design_event, author: project_owner) }
      let_it_be(:event_b) { create(:design_event, author: project_owner) }

      it 'only includes design events', :aggregate_failures do
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
