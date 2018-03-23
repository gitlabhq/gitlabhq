require 'rails_helper'

RSpec.describe Geo::ProjectSyncWorker do
  describe '#perform' do
    let(:project) { create(:project) }
    let(:repository_sync_service) { spy }
    let(:wiki_sync_service) { spy }

    before do
      allow(Geo::RepositorySyncService).to receive(:new)
        .with(instance_of(Project)).once.and_return(repository_sync_service)

      allow(Geo::WikiSyncService).to receive(:new)
        .with(instance_of(Project)).once.and_return(wiki_sync_service)
    end

    context 'when project could not be found' do
      it 'does not raise an error' do
        expect { subject.perform(999, Time.now) }.not_to raise_error
      end
    end

    context 'when project repositories has never been synced' do
      it 'performs Geo::RepositorySyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(repository_sync_service).to have_received(:execute).once
      end

      it 'performs Geo::WikiSyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(wiki_sync_service).to have_received(:execute).once
      end
    end

    context 'when project repositories has been synced' do
      let!(:registry) { create(:geo_project_registry, :synced, project: project) }

      it 'does not perform Geo::RepositorySyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(repository_sync_service).not_to have_received(:execute)
      end

      it 'does not perform Geo::WikiSyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(wiki_sync_service).not_to have_received(:execute)
      end
    end

    context 'when last attempt to sync project repositories failed' do
      let!(:registry) { create(:geo_project_registry, :sync_failed, project: project) }

      it 'performs Geo::RepositorySyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(repository_sync_service).to have_received(:execute).once
      end

      it 'performs Geo::WikiSyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(wiki_sync_service).to have_received(:execute).once
      end
    end

    context 'when project repository is dirty' do
      let!(:registry) do
        create(:geo_project_registry, :synced, :repository_dirty, project: project)
      end

      it 'performs Geo::RepositorySyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(repository_sync_service).to have_received(:execute).once
      end

      it 'does not perform Geo::WikiSyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(wiki_sync_service).not_to have_received(:execute)
      end
    end

    context 'when wiki is dirty' do
      let!(:registry) do
        create(:geo_project_registry, :synced, :wiki_dirty, project: project)
      end

      it 'does not perform Geo::RepositorySyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(repository_sync_service).not_to have_received(:execute)
      end

      it 'performs Geo::WikiSyncService for the given project' do
        subject.perform(project.id, Time.now)

        expect(wiki_sync_service).to have_received(:execute)
      end
    end

    context 'wiki is not enabled for project' do
      let!(:registry) { create(:geo_project_registry, resync_repository: true, resync_wiki: true, project: project) }

      before do
        project.update!(wiki_enabled: false)
        subject.perform(project.id, Time.now)
      end

      it 'syncs the project repository' do
        expect(repository_sync_service).to have_received(:execute)
      end

      it 'does not sync the project wiki' do
        expect(wiki_sync_service).not_to have_received(:execute)
      end

      it 'unflags wiki for sync, to remove it from Geo wiki queries' do
        expect(registry.reload.resync_wiki).to be_falsey
      end
    end

    context 'when project repository was synced after the time the job was scheduled in' do
      it 'does not perform Geo::RepositorySyncService for the given project' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project, last_repository_synced_at: Time.now)

        subject.perform(project.id, Time.now - 5.minutes)

        expect(repository_sync_service).not_to have_received(:execute)
      end
    end

    context 'when wiki repository was synced after the time the job was scheduled in' do
      it 'does not perform Geo::RepositorySyncService for the given project' do
        create(:geo_project_registry, :synced, :wiki_dirty, project: project, last_wiki_synced_at: Time.now)

        subject.perform(project.id, Time.now - 5.minutes)

        expect(wiki_sync_service).not_to have_received(:execute)
      end
    end
  end
end
