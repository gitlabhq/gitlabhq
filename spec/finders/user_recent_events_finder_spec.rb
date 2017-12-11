require 'spec_helper'

describe UserRecentEventsFinder do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:project_owner) { project.creator }
  let!(:event) { create(:event, project: project, author: project_owner) }

  subject(:finder) { described_class.new(user, project_owner) }

  describe '#execute' do
    it 'does not include the event when a user does not have access to the project' do
      expect(finder.execute).to be_empty
    end

    context 'when the user has access to a project' do
      before do
        project.add_developer(user)
      end

      it 'includes the event' do
        expect(finder.execute).to include(event)
      end

      it 'does not include the event if the user cannot read cross project' do
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
        expect(finder.execute).to be_empty
      end
    end
  end
end
