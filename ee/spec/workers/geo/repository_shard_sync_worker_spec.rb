require 'spec_helper'

# Disable transactions via :delete method because a foreign table
# can't see changes inside a transaction of a different connection.
describe Geo::RepositoryShardSyncWorker, :geo, :delete, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:primary) { create(:geo_node, :primary) }
  let!(:secondary) { create(:geo_node) }

  let!(:restricted_group) { create(:group) }

  let!(:unsynced_project_in_restricted_group) { create(:project, group: restricted_group) }
  let!(:unsynced_project) { create(:project) }

  let(:shard_name) { Gitlab.config.repositories.storages.keys.first }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples '#perform' do |skip_tests|
    before do
      skip('FDW is not configured') if skip_tests
    end

    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew) { true }

      Gitlab::Geo::ShardHealthCache.update([shard_name])
    end

    it 'performs Geo::ProjectSyncWorker for each project' do
      expect(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform(shard_name)
    end

    it 'performs Geo::ProjectSyncWorker for projects where last attempt to sync failed' do
      create(:geo_project_registry, :sync_failed, project: unsynced_project_in_restricted_group)
      create(:geo_project_registry, :synced, project: unsynced_project)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).once.and_return(spy)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::ProjectSyncWorker when shard becomes unhealthy' do
      Gitlab::Geo::ShardHealthCache.update([])

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'performs Geo::ProjectSyncWorker for synced projects updated recently' do
      create(:geo_project_registry, :synced, :repository_dirty, project: unsynced_project_in_restricted_group)
      create(:geo_project_registry, :synced, project: unsynced_project)
      create(:geo_project_registry, :synced, :wiki_dirty)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform(shard_name)
    end

    it 'does not schedule a job twice for the same project' do
      scheduled_jobs = [
        { job_id: 1, project_id: unsynced_project.id },
        { job_id: 2, project_id: unsynced_project_in_restricted_group.id }
      ]

      is_expected.to receive(:scheduled_jobs).and_return(scheduled_jobs).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    it 'does not perform Geo::ProjectSyncWorker when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not perform Geo::ProjectSyncWorker when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::ProjectSyncWorker when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    context 'multiple shards' do
      it 'uses two loops to schedule jobs' do
        expect(subject).to receive(:schedule_jobs).twice.and_call_original

        Gitlab::Geo::ShardHealthCache.update([shard_name, 'shard2', 'shard3', 'shard4', 'shard5'])
        secondary.update!(repos_max_capacity: 5)

        subject.perform(shard_name)
      end
    end

    context 'when node has namespace restrictions' do
      before do
        secondary.update!(selective_sync_type: 'namespaces', namespaces: [restricted_group])
      end

      it 'does not perform Geo::ProjectSyncWorker for projects that do not belong to selected namespaces to replicate' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(unsynced_project_in_restricted_group.id, within(1.minute).of(Time.now))
          .once
          .and_return(spy)

        subject.perform(shard_name)
      end

      it 'does not perform Geo::ProjectSyncWorker for synced projects updated recently that do not belong to selected namespaces to replicate' do
        create(:geo_project_registry, :synced, :repository_dirty, project: unsynced_project_in_restricted_group)
        create(:geo_project_registry, :synced, :repository_dirty, project: unsynced_project)

        expect(Geo::ProjectSyncWorker).to receive(:perform_async)
          .with(unsynced_project_in_restricted_group.id, within(1.minute).of(Time.now))
          .once
          .and_return(spy)

        subject.perform(shard_name)
      end
    end

    context 'repositories that have never been updated' do
      let!(:project_list) { create_list(:project, 4, last_repository_updated_at: 2.hours.ago) }
      let!(:abandoned_project) { create(:project) }

      before do
        # Project sync failed but never received an update
        create(:geo_project_registry, :repository_sync_failed, project: abandoned_project)
        abandoned_project.update_column(:last_repository_updated_at, 1.year.ago)

        # Neither of these are needed for this spec
        unsynced_project.destroy
        unsynced_project_in_restricted_group.destroy

        allow_any_instance_of(described_class).to receive(:db_retrieve_batch_size).and_return(2) # Must be >1 because of the Geo::BaseSchedulerWorker#interleave
        secondary.update!(repos_max_capacity: 3) # Must be more than db_retrieve_batch_size

        project_list.each do |project|
          allow(Geo::ProjectSyncWorker)
            .to receive(:perform_async)
              .with(project.id, anything)
              .and_call_original
        end

        allow_any_instance_of(Geo::ProjectRegistry).to receive(:wiki_sync_due?).and_return(false)
        allow_any_instance_of(Geo::RepositorySyncService).to receive(:expire_repository_caches)
      end

      it 'tries to sync project where last attempt to sync failed' do
        expect(Geo::ProjectSyncWorker)
          .to receive(:perform_async)
            .with(abandoned_project.id, anything)
            .at_least(:once)
            .and_return(spy)

        3.times do
          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end
    end

    context 'all repositories fail' do
      let!(:project_list) { create_list(:project, 4, :random_last_repository_updated_at) }

      before do
        # Neither of these are needed for this spec
        unsynced_project.destroy
        unsynced_project_in_restricted_group.destroy

        allow_any_instance_of(described_class).to receive(:db_retrieve_batch_size).and_return(2) # Must be >1 because of the Geo::BaseSchedulerWorker#interleave
        secondary.update!(repos_max_capacity: 3) # Must be more than db_retrieve_batch_size
        allow_any_instance_of(Project).to receive(:ensure_repository).and_raise(Gitlab::Shell::Error.new('foo'))
        allow_any_instance_of(Geo::ProjectRegistry).to receive(:wiki_sync_due?).and_return(false)
        allow_any_instance_of(Geo::RepositorySyncService).to receive(:expire_repository_caches)
      end

      it 'tries to sync every project' do
        project_list.each do |project|
          expect(Geo::ProjectSyncWorker)
            .to receive(:perform_async)
              .with(project.id, anything)
              .at_least(:once)
              .and_call_original
        end

        3.times do
          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end
    end

    context 'additional shards' do
      it 'skips backfill for projects on unhealthy shards' do
        missing_not_synced = create(:project, group: restricted_group)
        missing_not_synced.update_column(:repository_storage, 'unknown')
        missing_dirty = create(:project, group: restricted_group)
        missing_dirty.update_column(:repository_storage, 'unknown')

        create(:geo_project_registry, :synced, :repository_dirty, project: missing_dirty)

        expect(Geo::ProjectSyncWorker).to receive(:perform_async).with(unsynced_project_in_restricted_group.id, anything)
        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(missing_not_synced.id, anything)
        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(missing_dirty.id, anything)

        Sidekiq::Testing.inline! { subject.perform(shard_name) }
      end
    end

    context 'number of scheduled jobs exceeds capacity' do
      it 'schedules 0 jobs' do
        is_expected.to receive(:scheduled_job_ids).and_return(1..1000).at_least(:once)
        is_expected.not_to receive(:schedule_job)

        Sidekiq::Testing.inline! { subject.perform(shard_name) }
      end
    end
  end

  describe 'when PostgreSQL FDW is available', :geo do
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
