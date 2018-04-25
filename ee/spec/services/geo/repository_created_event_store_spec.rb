require 'spec_helper'

describe Geo::RepositoryCreatedEventStore do
  set(:project) { create(:project) }
  set(:secondary_node) { create(:geo_node) }

  subject(:create!) { described_class.new(project).create }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { create! }.not_to change(Geo::RepositoryCreatedEvent, :count)
    end

    context 'running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { create! }.not_to change(Geo::RepositoryCreatedEvent, :count)
      end

      it 'creates a created event' do
        expect { create! }.to change(Geo::RepositoryCreatedEvent, :count).by(1)
      end

      it 'tracks information for the created project' do
        create!

        event = Geo::RepositoryCreatedEvent.last

        expect(event).to have_attributes(
          project_id: project.id,
          repo_path: project.disk_path,
          wiki_path: project.wiki.disk_path,
          project_name: project.name,
          repository_storage_name: project.repository_storage
        )
      end

      it 'does not set a wiki path if the wiki is disabled' do
        project.update!(wiki_enabled: false)

        create!

        event = Geo::RepositoryCreatedEvent.last
        expect(event.wiki_path).to be_nil
      end
    end
  end
end
