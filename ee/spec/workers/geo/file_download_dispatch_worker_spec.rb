require 'spec_helper'

describe Geo::FileDownloadDispatchWorker, :geo do
  include ::EE::GeoHelpers

  let(:primary)   { create(:geo_node, :primary, host: 'primary-geo-node') }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew).and_return(true)
    allow_any_instance_of(described_class).to receive(:over_time?).and_return(false)
    WebMock.stub_request(:get, /primary-geo-node/).to_return(status: 200, body: "", headers: {})
  end

  subject { described_class.new }

  shared_examples '#perform' do |skip_tests|
    before do
      skip('FDW is not configured') if skip_tests
    end

    it 'does not schedule anything when tracking database is not configured' do
      create(:lfs_object, :with_file)

      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::FileDownloadWorker).not_to receive(:perform_async)

      subject.perform

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not schedule anything when node is disabled' do
      create(:lfs_object, :with_file)

      secondary.enabled = false
      secondary.save

      expect(Geo::FileDownloadWorker).not_to receive(:perform_async)

      subject.perform
    end

    context 'with LFS objects' do
      let!(:lfs_object_local_store) { create(:lfs_object, :with_file) }
      let!(:lfs_object_remote_store) { create(:lfs_object, :with_file) }

      before do
        stub_lfs_object_storage
        lfs_object_remote_store.file.migrate!(LfsObjectUploader::Store::REMOTE)
      end

      it 'filters S3-backed files' do
        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('lfs', lfs_object_local_store.id)
        expect(Geo::FileDownloadWorker).not_to receive(:perform_async).with('lfs', lfs_object_remote_store.id)

        subject.perform
      end

      context 'with files missing on the primary that are marked as synced' do
        let!(:lfs_object_file_missing_on_primary) { create(:lfs_object, :with_file) }

        before do
          Geo::FileRegistry.create!(file_type: :lfs, file_id: lfs_object_file_missing_on_primary.id, bytes: 1234, success: true, missing_on_primary: true)
        end

        it 'retries the files if there is spare capacity' do
          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('lfs', lfs_object_local_store.id)
          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('lfs', lfs_object_file_missing_on_primary.id)

          subject.perform
        end

        it 'does not retry those files if there is no spare capacity' do
          expect(subject).to receive(:db_retrieve_batch_size).and_return(1).twice

          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('lfs', lfs_object_local_store.id)

          subject.perform
        end

        it 'does not retry those files if they are already scheduled' do
          scheduled_jobs = [{ type: 'lfs', id: lfs_object_file_missing_on_primary.id, job_id: 'foo' }]
          expect(subject).to receive(:scheduled_jobs).and_return(scheduled_jobs).at_least(1)
          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('lfs', lfs_object_local_store.id)

          subject.perform
        end
      end
    end

    context 'with job artifacts' do
      it 'performs Geo::FileDownloadWorker for unsynced job artifacts' do
        artifact = create(:ci_job_artifact)

        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', artifact.id)

        subject.perform
      end

      it 'performs Geo::FileDownloadWorker for failed-sync job artifacts' do
        artifact = create(:ci_job_artifact)

        create(:geo_job_artifact_registry, artifact_id: artifact.id, bytes: 0, success: false)

        expect(Geo::FileDownloadWorker).to receive(:perform_async)
          .with('job_artifact', artifact.id).once.and_return(spy)

        subject.perform
      end

      it 'does not perform Geo::FileDownloadWorker for synced job artifacts' do
        artifact = create(:ci_job_artifact)

        create(:geo_job_artifact_registry, artifact_id: artifact.id, bytes: 1234, success: true)

        expect(Geo::FileDownloadWorker).not_to receive(:perform_async)

        subject.perform
      end

      it 'does not perform Geo::FileDownloadWorker for synced job artifacts even with 0 bytes downloaded' do
        artifact = create(:ci_job_artifact)

        create(:geo_job_artifact_registry, artifact_id: artifact.id, bytes: 0, success: true)

        expect(Geo::FileDownloadWorker).not_to receive(:perform_async)

        subject.perform
      end

      it 'does not retry failed artifacts when retry_at is tomorrow' do
        failed_registry = create(:geo_job_artifact_registry, :with_artifact, bytes: 0, success: false, retry_at: Date.tomorrow)

        expect(Geo::FileDownloadWorker).not_to receive(:perform_async).with('job_artifact', failed_registry.artifact_id)

        subject.perform
      end

      it 'retries failed artifacts when retry_at is in the past' do
        failed_registry = create(:geo_job_artifact_registry, :with_artifact, success: false, retry_at: Date.yesterday)

        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', failed_registry.artifact_id)

        subject.perform
      end

      context 'with files missing on the primary that are marked as synced' do
        let!(:artifact_file_missing_on_primary) { create(:ci_job_artifact) }
        let!(:artifact_registry) { create(:geo_job_artifact_registry, artifact_id: artifact_file_missing_on_primary.id, bytes: 1234, success: true, missing_on_primary: true) }

        it 'retries the files if there is spare capacity' do
          artifact = create(:ci_job_artifact)

          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', artifact.id)
          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', artifact_file_missing_on_primary.id)

          subject.perform
        end

        it 'retries failed files with retry_at in the past' do
          artifact_registry.update!(retry_at: Date.yesterday)

          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', artifact_file_missing_on_primary.id)

          subject.perform
        end

        it 'does not retry files with later retry_at' do
          artifact_registry.update!(retry_at: Date.tomorrow)

          expect(Geo::FileDownloadWorker).not_to receive(:perform_async).with('job_artifact', artifact_file_missing_on_primary.id)

          subject.perform
        end

        it 'does not retry those files if there is no spare capacity' do
          artifact = create(:ci_job_artifact)

          expect(subject).to receive(:db_retrieve_batch_size).and_return(1).twice
          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', artifact.id)

          subject.perform
        end

        it 'does not retry those files if they are already scheduled' do
          artifact = create(:ci_job_artifact)

          scheduled_jobs = [{ type: 'job_artifact', id: artifact_file_missing_on_primary.id, job_id: 'foo' }]
          expect(subject).to receive(:scheduled_jobs).and_return(scheduled_jobs).at_least(1)
          expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', artifact.id)

          subject.perform
        end
      end
    end

    # Test the case where we have:
    #
    # 1. A total of 10 files in the queue, and we can load a maximimum of 5 and send 2 at a time.
    # 2. We send 2, wait for 1 to finish, and then send again.
    it 'attempts to load a new batch without pending downloads' do
      stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 5)
      secondary.update!(files_max_capacity: 2)
      result_object = double(:result, success: true, bytes_downloaded: 100, primary_missing_file: false)
      allow_any_instance_of(::Gitlab::Geo::Transfer).to receive(:download_from_primary).and_return(result_object)

      avatar = fixture_file_upload(Rails.root.join('spec/fixtures/dk.png'))
      create_list(:lfs_object, 2, :with_file)
      create_list(:user, 2, avatar: avatar)
      create_list(:note, 2, :with_attachment)
      create_list(:upload, 1, :personal_snippet_upload)
      create_list(:ci_job_artifact, 1)
      create(:appearance, logo: avatar, header_logo: avatar)

      expect(Geo::FileDownloadWorker).to receive(:perform_async).exactly(10).times.and_call_original
      # For 10 downloads, we expect four database reloads:
      # 1. Load the first batch of 5.
      # 2. 4 get sent out, 1 remains. This triggers another reload, which loads in the next 5.
      # 3. Those 4 get sent out, and 1 remains.
      # 3. Since the second reload filled the pipe with 4, we need to do a final reload to ensure
      #    zero are left.
      expect(subject).to receive(:load_pending_resources).exactly(4).times.and_call_original

      Sidekiq::Testing.inline! do
        subject.perform
      end
    end

    context 'with a failed file' do
      let(:failed_registry) { create(:geo_file_registry, :lfs, file_id: 999, success: false) }

      it 'does not stall backfill' do
        unsynced = create(:lfs_object, :with_file)

        stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 1)

        expect(Geo::FileDownloadWorker).not_to receive(:perform_async).with('lfs', failed_registry.file_id)
        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('lfs', unsynced.id)

        subject.perform
      end

      it 'retries failed files' do
        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('lfs', failed_registry.file_id)

        subject.perform
      end

      it 'does not retry failed files when retry_at is tomorrow' do
        failed_registry = create(:geo_file_registry, :lfs, file_id: 999, success: false, retry_at: Date.tomorrow)

        expect(Geo::FileDownloadWorker).not_to receive(:perform_async).with('lfs', failed_registry.file_id)

        subject.perform
      end

      it 'retries failed files when retry_at is in the past' do
        failed_registry = create(:geo_file_registry, :lfs, file_id: 999, success: false, retry_at: Date.yesterday)

        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('lfs', failed_registry.file_id)

        subject.perform
      end
    end

    context 'with Upload files missing on the primary that are marked as synced' do
      let(:synced_upload_with_file_missing_on_primary) { create(:upload) }

      before do
        Geo::FileRegistry.create!(file_type: :avatar, file_id: synced_upload_with_file_missing_on_primary.id, bytes: 1234, success: true, missing_on_primary: true)
      end

      it 'retries the files if there is spare capacity' do
        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('avatar', synced_upload_with_file_missing_on_primary.id)

        subject.perform
      end

      it 'does not retry those files if there is no spare capacity' do
        unsynced_upload = create(:upload)
        expect(subject).to receive(:db_retrieve_batch_size).and_return(1).twice

        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('avatar', unsynced_upload.id)

        subject.perform
      end

      it 'does not retry those files if they are already scheduled' do
        unsynced_upload = create(:upload)

        scheduled_jobs = [{ type: 'avatar', id: synced_upload_with_file_missing_on_primary.id, job_id: 'foo' }]
        expect(subject).to receive(:scheduled_jobs).and_return(scheduled_jobs).at_least(1)
        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('avatar', unsynced_upload.id)

        subject.perform
      end
    end

    context 'when node has namespace restrictions' do
      let(:synced_group) { create(:group) }
      let(:project_in_synced_group) { create(:project, group: synced_group) }
      let(:unsynced_project) { create(:project) }

      before do
        allow(ProjectCacheWorker).to receive(:perform_async).and_return(true)

        secondary.update!(selective_sync_type: 'namespaces', namespaces: [synced_group])
      end

      it 'does not perform Geo::FileDownloadWorker for LFS object that does not belong to selected namespaces to replicate' do
        lfs_object_in_synced_group = create(:lfs_objects_project, project: project_in_synced_group)
        create(:lfs_objects_project, project: unsynced_project)

        expect(Geo::FileDownloadWorker).to receive(:perform_async)
          .with('lfs', lfs_object_in_synced_group.lfs_object_id).once.and_return(spy)

        subject.perform
      end

      it 'does not perform Geo::FileDownloadWorker for job artifact that does not belong to selected namespaces to replicate' do
        create(:ci_job_artifact, project: unsynced_project)
        job_artifact_in_synced_group = create(:ci_job_artifact, project: project_in_synced_group)

        expect(Geo::FileDownloadWorker).to receive(:perform_async)
          .with('job_artifact', job_artifact_in_synced_group.id).once.and_return(spy)

        subject.perform
      end

      it 'does not perform Geo::FileDownloadWorker for upload objects that do not belong to selected namespaces to replicate' do
        avatar = fixture_file_upload(Rails.root.join('spec/fixtures/dk.png'))
        avatar_in_synced_group = create(:upload, model: synced_group, path: avatar)
        create(:upload, model: create(:group), path: avatar)
        avatar_in_project_in_synced_group = create(:upload, model: project_in_synced_group, path: avatar)
        create(:upload, model: unsynced_project, path: avatar)

        expect(Geo::FileDownloadWorker).to receive(:perform_async)
          .with('avatar', avatar_in_project_in_synced_group.id).once.and_return(spy)

        expect(Geo::FileDownloadWorker).to receive(:perform_async)
          .with('avatar', avatar_in_synced_group.id).once.and_return(spy)

        subject.perform
      end
    end
  end

  # Disable transactions via :delete method because a foreign table
  # can't see changes inside a transaction of a different connection.
  describe 'when PostgreSQL FDW is available', :geo, :delete do
    # Skip if FDW isn't activated on this database
    it_behaves_like '#perform', Gitlab::Database.postgresql? && !Gitlab::Geo::Fdw.enabled?
  end

  describe 'when PostgreSQL FDW is not enabled', :geo do
    before do
      allow(Gitlab::Geo::Fdw).to receive(:enabled?).and_return(false)
    end

    it_behaves_like '#perform', false
  end
end
