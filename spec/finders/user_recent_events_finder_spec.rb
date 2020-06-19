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

  subject(:finder) { described_class.new(current_user, project_owner) }

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

    describe 'design_activity_events feature flag' do
      let_it_be(:event_a) { create(:design_event, author: project_owner) }
      let_it_be(:event_b) { create(:design_event, author: project_owner) }

      context 'the design_activity_events feature-flag is enabled' do
        it 'only includes design events in enabled projects', :aggregate_failures do
          events = finder.execute

          expect(events).to include(event_a)
          expect(events).to include(event_b)
        end
      end

      context 'the design_activity_events feature-flag is disabled' do
        it 'excludes design events', :aggregate_failures do
          stub_feature_flags(design_activity_events: false)

          events = finder.execute

          expect(events).not_to include(event_a)
          expect(events).not_to include(event_b)
        end
      end
    end
  end
end
