require 'spec_helper'

describe UserRecentEventsFinder do
  let(:current_user)     { create(:user) }
  let(:project_owner)    { create(:user) }
  let(:private_project)  { create(:project, :private, creator: project_owner) }
  let(:internal_project) { create(:project, :internal, creator: project_owner) }
  let(:public_project)   { create(:project, :public, creator: project_owner) }
  let!(:private_event)   { create(:event, project: private_project, author: project_owner) }
  let!(:internal_event)  { create(:event, project: internal_project, author: project_owner) }
  let!(:public_event)    { create(:event, project: public_project, author: project_owner) }

  subject(:finder) { described_class.new(current_user, project_owner) }

  describe '#execute' do
    context 'current user does not have access to projects' do
      it 'returns public and internal events' do
        records = finder.execute

        expect(records).to include(public_event, internal_event)
        expect(records).not_to include(private_event)
      end
    end

    context 'when current user has access to the projects' do
      before do
        private_project.add_developer(current_user)
        internal_project.add_developer(current_user)
        public_project.add_developer(current_user)
      end

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
        expect(Ability).to receive(:allowed?).and_call_original
        expect(Ability).to receive(:allowed?).with(current_user, :read_cross_project) { false }
        expect(finder.execute).to be_empty
      end
    end

    context 'when current user is anonymous' do
      let(:current_user) { nil }

      it 'returns public events only' do
        expect(finder.execute).to eq([public_event])
      end
    end
  end
end
