require 'spec_helper'

describe Gitlab::Geo::LogCursor::Daemon, :postgresql, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers

  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  let(:options) { {} }

  subject(:daemon) { described_class.new(options) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  before do
    stub_current_geo_node(secondary)

    allow(daemon).to receive(:trap_signals)
    allow(daemon).to receive(:arbitrary_sleep).and_return(0.1)
  end

  describe '#run!' do
    it 'traps signals' do
      is_expected.to receive(:exit?).and_return(true)
      is_expected.to receive(:trap_signals)

      daemon.run!
    end

    it 'delegates to #run_once! in a loop' do
      is_expected.to receive(:exit?).and_return(false, false, false, true)
      is_expected.to receive(:run_once!).twice

      daemon.run!
    end

    it 'skips execution if cannot achieve a lease' do
      is_expected.to receive(:exit?).and_return(false, true)
      is_expected.not_to receive(:run_once!)
      expect_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain_with_ttl).and_return({ ttl: 1, uuid: false })

      daemon.run!
    end

    it 'skips execution if not a Geo node' do
      stub_current_geo_node(nil)

      is_expected.to receive(:exit?).and_return(false, true)
      is_expected.to receive(:sleep).with(1.minute)
      is_expected.not_to receive(:run_once!)

      daemon.run!
    end

    it 'skips execution if the current node is a primary' do
      stub_current_geo_node(primary)

      is_expected.to receive(:exit?).and_return(false, true)
      is_expected.to receive(:sleep).with(1.minute)
      is_expected.not_to receive(:run_once!)

      daemon.run!
    end
  end

  describe '#run_once!' do
    context 'when replaying a repository created event' do
      let(:project) { create(:project) }
      let(:repository_created_event) { create(:geo_repository_created_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_created_event: repository_created_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      it 'creates a new project registry' do
        expect { daemon.run_once! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'sets resync attributes to true' do
        daemon.run_once!

        registry = Geo::ProjectRegistry.last

        expect(registry).to have_attributes(project_id: project.id, resync_repository: true, resync_wiki: true)
      end

      it 'sets resync_wiki to false if wiki_path is nil' do
        repository_created_event.update!(wiki_path: nil)

        daemon.run_once!

        registry = Geo::ProjectRegistry.last

        expect(registry).to have_attributes(project_id: project.id, resync_repository: true, resync_wiki: false)
      end

      it 'performs Geo::ProjectSyncWorker' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project.id, anything).once

        daemon.run_once!
      end
    end

    context 'when replaying a repository updated event' do
      let(:project) { create(:project) }
      let(:repository_updated_event) { create(:geo_repository_updated_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_updated_event: repository_updated_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      it 'creates a new project registry if it does not exist' do
        expect { daemon.run_once! }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      context 'when event source is repository' do
        let!(:registry) { create(:geo_project_registry, :synced, :repository_verified, :repository_checksum_mismatch, project: repository_updated_event.project) }

        before do
          repository_updated_event.update!(source: Geo::RepositoryUpdatedEvent::REPOSITORY)
        end

        it 'sets resync_repository to true' do
          daemon.run_once!

          expect(registry.reload.resync_repository).to be true
        end

        it 'resets the repository verification fields' do
          daemon.run_once!

          expect(registry.reload).to have_attributes(
            repository_verification_checksum_sha: nil,
            repository_checksum_mismatch: false,
            last_repository_verification_failure: nil
          )
        end
      end

      context 'when event source is wiki' do
        let!(:registry) { create(:geo_project_registry, :synced, :wiki_verified, :wiki_checksum_mismatch, project: repository_updated_event.project) }

        before do
          repository_updated_event.update!(source: Geo::RepositoryUpdatedEvent::WIKI)
        end

        it 'sets resync_wiki to true' do
          daemon.run_once!

          expect(registry.reload.resync_wiki).to be true
        end

        it 'resets the wiki repository verification fields' do
          daemon.run_once!

          expect(registry.reload).to have_attributes(
            wiki_verification_checksum_sha: nil,
            wiki_checksum_mismatch: false,
            last_wiki_verification_failure: nil
          )
        end
      end

      it 'performs Geo::ProjectSyncWorker' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project.id, anything).once

        daemon.run_once!
      end
    end

    context 'when replaying a repository deleted event' do
      let(:event_log) { create(:geo_event_log, :deleted_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:repository_deleted_event) { event_log.repository_deleted_event }
      let(:project) { repository_deleted_event.project }
      let(:deleted_project_name) { repository_deleted_event.deleted_project_name }
      let(:deleted_path) { repository_deleted_event.deleted_path }

      context 'when a tracking entry does not exist' do
        it 'does not schedule a GeoRepositoryDestroyWorker' do
          expect(::GeoRepositoryDestroyWorker).not_to receive(:perform_async)
            .with(project.id, deleted_project_name, deleted_path, project.repository_storage)

          daemon.run_once!
        end

        it 'does not create a tracking entry' do
          expect { daemon.run_once! }.not_to change(Geo::ProjectRegistry, :count)
        end
      end

      context 'when a tracking entry exists' do
        let!(:tracking_entry) { create(:geo_project_registry, project: project) }

        it 'schedules a GeoRepositoryDestroyWorker' do
          expect(::GeoRepositoryDestroyWorker).to receive(:perform_async)
            .with(project.id, deleted_project_name, deleted_path, project.repository_storage)

          daemon.run_once!
        end

        it 'removes the tracking entry' do
          expect { daemon.run_once! }.to change(Geo::ProjectRegistry, :count).by(-1)
        end
      end
    end

    context 'when replaying a repositories changed event' do
      let(:repositories_changed_event) { create(:geo_repositories_changed_event, geo_node: secondary) }
      let(:event_log) { create(:geo_event_log, repositories_changed_event: repositories_changed_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

      it 'schedules a GeoRepositoryDestroyWorker when event node is the current node' do
        expect(Geo::RepositoriesCleanUpWorker).to receive(:perform_in).with(within(5.minutes).of(1.hour), secondary.id)

        daemon.run_once!
      end

      it 'does not schedule a GeoRepositoryDestroyWorker when event node is not the current node' do
        stub_current_geo_node(build(:geo_node))

        expect(Geo::RepositoriesCleanUpWorker).not_to receive(:perform_in)

        daemon.run_once!
      end
    end

    context 'when node has namespace restrictions' do
      let(:group_1) { create(:group) }
      let(:group_2) { create(:group) }
      let(:project) { create(:project, group: group_1) }
      let(:repository_updated_event) { create(:geo_repository_updated_event, project: project) }
      let(:event_log) { create(:geo_event_log, repository_updated_event: repository_updated_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let!(:registry) { create(:geo_project_registry, :synced, project: project) }

      it 'replays events for projects that belong to selected namespaces to replicate' do
        secondary.update!(namespaces: [group_1])

        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(project.id, anything).once

        daemon.run_once!
      end

      it 'does not replay events for projects that do not belong to selected namespaces to replicate' do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [group_2])

        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)
          .with(project.id, anything)

        daemon.run_once!
      end

      it 'does not replay events for projects that do not belong to selected shards to replicate' do
        secondary.update!(selective_sync_type: 'shards', selective_sync_shards: ['broken'])

        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)
          .with(project.id, anything)

        daemon.run_once!
      end
    end

    context 'when processing a repository renamed event' do
      let(:event_log) { create(:geo_event_log, :renamed_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:repository_renamed_event) { event_log.repository_renamed_event }
      let(:project) {repository_renamed_event.project }
      let(:old_path_with_namespace) { repository_renamed_event.old_path_with_namespace }
      let(:new_path_with_namespace) { repository_renamed_event.new_path_with_namespace }

      context 'when a tracking entry does not exist' do
        it 'does not create a tracking entry' do
          expect { daemon.run_once! }.not_to change(Geo::ProjectRegistry, :count)
        end

        it 'does not schedule a Geo::RenameRepositoryWorker' do
          expect(::Geo::RenameRepositoryWorker).not_to receive(:perform_async)
            .with(project.id, old_path_with_namespace, new_path_with_namespace)

          daemon.run_once!
        end
      end

      context 'when a tracking entry does exists' do
        it 'schedules a Geo::RenameRepositoryWorker' do
          create(:geo_project_registry, project: project)

          expect(::Geo::RenameRepositoryWorker).to receive(:perform_async)
            .with(project.id, old_path_with_namespace, new_path_with_namespace)

          daemon.run_once!
        end
      end
    end

    context 'when processing a hashed storage migration event' do
      let(:event_log) { create(:geo_event_log, :hashed_storage_migration_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:hashed_storage_migrated_event) { event_log.hashed_storage_migrated_event }
      let(:project) { hashed_storage_migrated_event.project }
      let(:old_disk_path) { hashed_storage_migrated_event.old_disk_path }
      let(:new_disk_path) { hashed_storage_migrated_event.new_disk_path }
      let(:old_storage_version) { hashed_storage_migrated_event.old_storage_version }

      context 'when a tracking entry does not exist' do
        it 'does not create a tracking entry' do
          expect { daemon.run_once! }.not_to change(Geo::ProjectRegistry, :count)
        end

        it 'does not schedule a Geo::HashedStorageMigrationWorker' do
          expect(::Geo::HashedStorageMigrationWorker).not_to receive(:perform_async)
            .with(project.id, old_disk_path, new_disk_path, old_storage_version)

          daemon.run_once!
        end
      end

      context 'when a tracking entry exists' do
        it 'schedules a Geo::HashedStorageMigrationWorker' do
          create(:geo_project_registry, project: project)

          expect(::Geo::HashedStorageMigrationWorker).to receive(:perform_async)
            .with(project.id, old_disk_path, new_disk_path, old_storage_version)

          daemon.run_once!
        end
      end
    end

    context 'when processing an attachment migration event to hashed storage' do
      let(:event_log) { create(:geo_event_log, :hashed_storage_attachments_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:hashed_storage_attachments_event) { event_log.hashed_storage_attachments_event }

      it 'does not create a new project registry' do
        expect { daemon.run_once! }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'schedules a Geo::HashedStorageAttachmentsMigrationWorker' do
        project = hashed_storage_attachments_event.project
        old_attachments_path = hashed_storage_attachments_event.old_attachments_path
        new_attachments_path = hashed_storage_attachments_event.new_attachments_path

        expect(::Geo::HashedStorageAttachmentsMigrationWorker).to receive(:perform_async)
          .with(project.id, old_attachments_path, new_attachments_path)

        daemon.run_once!
      end
    end

    context 'when replaying a LFS object deleted event' do
      let(:event_log) { create(:geo_event_log, :lfs_object_deleted_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:lfs_object_deleted_event) { event_log.lfs_object_deleted_event }
      let(:lfs_object) { lfs_object_deleted_event.lfs_object }

      it 'does not create a tracking database entry' do
        expect { daemon.run_once! }.not_to change(Geo::FileRegistry, :count)
      end

      it 'schedules a Geo::FileRemovalWorker' do
        file_path = File.join(LfsObjectUploader.root, lfs_object_deleted_event.file_path)

        expect(::Geo::FileRemovalWorker).to receive(:perform_async)
          .with(file_path)

        daemon.run_once!
      end

      it 'removes the tracking database entry if exist' do
        create(:geo_file_registry, :lfs, file_id: lfs_object.id)

        expect { daemon.run_once! }.to change(Geo::FileRegistry.lfs_objects, :count).by(-1)
      end
    end

    context 'when replaying a upload deleted event' do
      context 'with default handling' do
        let(:event_log) { create(:geo_event_log, :upload_deleted_event) }
        let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
        let(:upload_deleted_event) { event_log.upload_deleted_event }
        let(:upload) { upload_deleted_event.upload }

        it 'does not create a tracking database entry' do
          expect { daemon.run_once! }.not_to change(Geo::FileRegistry, :count)
        end

        it 'removes the tracking database entry if exist' do
          create(:geo_file_registry, :avatar, file_id: upload.id)

          expect { daemon.run_once! }.to change(Geo::FileRegistry.attachments, :count).by(-1)
        end
      end
    end

    context 'when replaying a job artifact event' do
      let(:event_log) { create(:geo_event_log, :job_artifact_deleted_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:job_artifact_deleted_event) { event_log.job_artifact_deleted_event }
      let(:job_artifact) { job_artifact_deleted_event.job_artifact }

      context 'with a tracking database entry' do
        before do
          create(:geo_job_artifact_registry, artifact_id: job_artifact.id)
        end

        context 'with a file' do
          context 'when the delete succeeds' do
            it 'removes the tracking database entry' do
              expect { daemon.run_once! }.to change(Geo::JobArtifactRegistry, :count).by(-1)
            end

            it 'deletes the file' do
              expect { daemon.run_once! }.to change { File.exist?(job_artifact.file.path) }.from(true).to(false)
            end
          end

          context 'when the delete fails' do
            before do
              expect(daemon).to receive(:delete_file).and_return(false)
            end

            it 'does not remove the tracking database entry' do
              expect { daemon.run_once! }.not_to change(Geo::JobArtifactRegistry, :count)
            end
          end
        end

        context 'without a file' do
          before do
            FileUtils.rm(job_artifact.file.path)
          end

          it 'removes the tracking database entry' do
            expect { daemon.run_once! }.to change(Geo::JobArtifactRegistry, :count).by(-1)
          end
        end
      end

      context 'without a tracking database entry' do
        it 'does not create a tracking database entry' do
          expect { daemon.run_once! }.not_to change(Geo::JobArtifactRegistry, :count)
        end

        it 'does not delete the file (yet, due to possible race condition)' do
          expect { daemon.run_once! }.not_to change { File.exist?(job_artifact.file.path) }.from(true)
        end
      end
    end
  end

  describe '#delete_file' do
    context 'when the file exists' do
      let!(:file) { fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png") }

      context 'when the delete does not raise an exception' do
        it 'returns true' do
          expect(daemon.send(:delete_file, file.path)).to be_truthy
        end

        it 'does not log an error' do
          expect(daemon).not_to receive(:logger)

          daemon.send(:delete_file, file.path)
        end
      end

      context 'when the delete raises an exception' do
        before do
          expect(File).to receive(:delete).and_raise('something went wrong')
        end

        it 'returns false' do
          expect(daemon.send(:delete_file, file.path)).to be_falsey
        end

        it 'logs an error' do
          logger = double(logger)
          expect(daemon).to receive(:logger).and_return(logger)
          expect(logger).to receive(:error).with('Failed to remove file', exception: 'RuntimeError', details: 'something went wrong', filename: file.path)

          daemon.send(:delete_file, file.path)
        end
      end
    end

    context 'when the file does not exist' do
      it 'returns false' do
        expect(daemon.send(:delete_file, '/does/not/exist')).to be_falsey
      end

      it 'logs an error' do
        logger = double(logger)
        expect(daemon).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with('Failed to remove file', exception: 'Errno::ENOENT', details: 'No such file or directory @ unlink_internal - /does/not/exist', filename: '/does/not/exist')

        daemon.send(:delete_file, '/does/not/exist')
      end
    end
  end
end
