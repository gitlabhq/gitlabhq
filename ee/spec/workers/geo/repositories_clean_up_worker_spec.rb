require 'spec_helper'

describe Geo::RepositoriesCleanUpWorker do
  describe '#perform' do
    let(:geo_node) { create(:geo_node) }

    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
    end

    context 'when node has namespace restrictions' do
      let(:synced_group) { create(:group) }
      let(:geo_node) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

      context 'legacy storage' do
        it 'performs GeoRepositoryDestroyWorker for each project that does not belong to selected namespaces to replicate' do
          project_in_synced_group = create(:project, :legacy_storage, group: synced_group)
          unsynced_project = create(:project, :repository, :legacy_storage)
          disk_path = "#{unsynced_project.namespace.full_path}/#{unsynced_project.path}"

          expect(GeoRepositoryDestroyWorker).to receive(:perform_async)
            .with(unsynced_project.id, unsynced_project.name, disk_path, unsynced_project.repository.storage)
            .once.and_return(1)

          expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)
            .with(project_in_synced_group.id, project_in_synced_group.name, project_in_synced_group.disk_path, project_in_synced_group.repository.storage)

          subject.perform(geo_node.id)
        end
      end

      context 'hashed storage' do
        before do
          stub_application_setting(hashed_storage_enabled: true)
        end

        it 'performs GeoRepositoryDestroyWorker for each project that does not belong to selected namespaces to replicate' do
          project_in_synced_group = create(:project, group: synced_group)
          unsynced_project = create(:project, :repository)

          hash = Digest::SHA2.hexdigest(unsynced_project.id.to_s)
          disk_path = "@hashed/#{hash[0..1]}/#{hash[2..3]}/#{hash}"

          expect(GeoRepositoryDestroyWorker).to receive(:perform_async)
            .with(unsynced_project.id, unsynced_project.name, disk_path, unsynced_project.repository.storage)
            .once.and_return(1)

          expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)
            .with(project_in_synced_group.id, project_in_synced_group.name, project_in_synced_group.disk_path, project_in_synced_group.repository.storage)

          subject.perform(geo_node.id)
        end
      end

      it 'does not perform GeoRepositoryDestroyWorker when repository does not exist' do
        create(:project)

        expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)

        subject.perform(geo_node.id)
      end
    end

    it 'does not perform GeoRepositoryDestroyWorker when does not node have namespace restrictions' do
      expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)

      subject.perform(geo_node.id)
    end

    it 'does not perform GeoRepositoryDestroyWorker when cannnot obtain a lease' do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { false }

      expect(GeoRepositoryDestroyWorker).not_to receive(:perform_async)

      subject.perform(geo_node.id)
    end

    it 'does not raise an error when node could not be found' do
      expect { subject.perform(-1) }.not_to raise_error
    end
  end
end
