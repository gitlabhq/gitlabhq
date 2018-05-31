require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::HashedStorageMigratedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :hashed_storage_migration_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:hashed_storage_migrated_event) { event_log.hashed_storage_migrated_event }
  let(:project) { hashed_storage_migrated_event.project }
  let(:old_disk_path) { hashed_storage_migrated_event.old_disk_path }
  let(:new_disk_path) { hashed_storage_migrated_event.new_disk_path }
  let(:old_storage_version) { hashed_storage_migrated_event.old_storage_version }

  subject { described_class.new(hashed_storage_migrated_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  describe '#process' do
    context 'when a tracking entry does not exist' do
      it 'does not create a tracking entry' do
        expect { subject.process }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'does not schedule a Geo::HashedStorageMigrationWorker' do
        expect(::Geo::HashedStorageMigrationWorker).not_to receive(:perform_async)
          .with(project.id, old_disk_path, new_disk_path, old_storage_version)

        subject.process
      end
    end

    it 'schedules a Geo::HashedStorageMigrationWorker' do
      create(:geo_project_registry, project: project)

      expect(::Geo::HashedStorageMigrationWorker).to receive(:perform_async)
        .with(project.id, old_disk_path, new_disk_path, old_storage_version)

      subject.process
    end
  end
end
