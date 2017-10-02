require 'spec_helper'

describe Projects::HashedStorageMigrationService do
  let(:project) { create(:project, :empty_repo, :wiki_repo) }
  let(:service) { described_class.new(project) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }

  describe '#execute' do
    it 'creates a Geo::RepositoryRenamedEvent on success' do
      allow(Gitlab::Geo).to receive(:primary?).and_return(true)

      expect { service.execute }.to change { Geo::EventLog.count }.by(1)

      event = Geo::EventLog.first.event

      expect(event).to be_a(Geo::RepositoryRenamedEvent)
      expect(event).to have_attributes(
        old_path: project.path,
        new_path: project.path,
        old_path_with_namespace: legacy_storage.disk_path,
        new_path_with_namespace: hashed_storage.disk_path,
        old_wiki_path_with_namespace: legacy_storage.disk_path + '.wiki',
        new_wiki_path_with_namespace: hashed_storage.disk_path + '.wiki'
      )
    end

    it 'does not create a Geo event on failure' do
      from_name = project.disk_path
      to_name = hashed_storage.disk_path

      allow(service).to receive(:move_repository).and_call_original
      allow(service).to receive(:move_repository).with(from_name, to_name).once { false } # will disable first move only

      allow(Gitlab::Geo).to receive(:primary?).and_return(true)
      expect { service.execute }.not_to change { Geo::EventLog.count }
    end
  end
end
