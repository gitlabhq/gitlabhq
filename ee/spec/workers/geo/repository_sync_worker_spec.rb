require 'spec_helper'

describe Geo::RepositorySyncWorker, :geo, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:primary) { create(:geo_node, :primary) }
  let!(:secondary) { create(:geo_node) }
  let!(:synced_group) { create(:group) }
  let!(:project_in_synced_group) { create(:project, group: synced_group) }
  let!(:unsynced_project) { create(:project) }

  let(:healthy_shard) { project_in_synced_group.repository.storage }

  subject { described_class.new }

  before do
    stub_current_geo_node(secondary)
  end

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  describe '#perform' do
    context 'additional shards' do
      it 'skips backfill for repositories on other shards' do
        unhealthy_not_synced = create(:project, group: synced_group, repository_storage: 'broken')
        unhealthy_dirty = create(:project, group: synced_group, repository_storage: 'broken')

        create(:geo_project_registry, :synced, :repository_dirty, project: unhealthy_dirty)

        # Make the shard unhealthy
        FileUtils.rm_rf(unhealthy_not_synced.repository_storage_path)

        expect(Geo::RepositoryShardSyncWorker).to receive(:perform_async).with(project_in_synced_group.repository.storage)
        expect(Geo::RepositoryShardSyncWorker).not_to receive(:perform_async).with('broken')

        subject.perform
      end

      it 'skips backfill for projects on shards excluded by selective sync' do
        secondary.update!(selective_sync_type: 'shards', selective_sync_shards: [healthy_shard])

        # Report both shards as healthy
        expect(Gitlab::HealthChecks::FsShardsCheck).to receive(:readiness)
          .and_return([result(true, healthy_shard), result(true, 'broken')])
        expect(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness)
          .and_return([result(true, healthy_shard), result(true, 'broken')])

        expect(Geo::RepositoryShardSyncWorker).to receive(:perform_async).with('default')
        expect(Geo::RepositoryShardSyncWorker).not_to receive(:perform_async).with('broken')

        subject.perform
      end

      it 'skips backfill for projects on missing shards' do
        missing_not_synced = create(:project, group: synced_group)
        missing_not_synced.update_column(:repository_storage, 'unknown')
        missing_dirty = create(:project, group: synced_group)
        missing_dirty.update_column(:repository_storage, 'unknown')

        create(:geo_project_registry, :synced, :repository_dirty, project: missing_dirty)

        # hide the 'broken' storage for this spec
        stub_storage_settings({})

        expect(Geo::RepositoryShardSyncWorker).to receive(:perform_async).with(project_in_synced_group.repository.storage)
        expect(Geo::RepositoryShardSyncWorker).not_to receive(:perform_async).with('unknown')

        subject.perform
      end

      it 'skips backfill for projects with downed Gitaly server' do
        create(:project, group: synced_group, repository_storage: 'broken')
        unhealthy_dirty = create(:project, group: synced_group, repository_storage: 'broken')

        create(:geo_project_registry, :synced, :repository_dirty, project: unhealthy_dirty)

        # Report only one healthy shard
        expect(Gitlab::HealthChecks::FsShardsCheck).to receive(:readiness)
          .and_return([result(true, healthy_shard), result(true, 'broken')])
        expect(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness)
          .and_return([result(true, healthy_shard), result(false, 'broken')])

        expect(Geo::RepositoryShardSyncWorker).to receive(:perform_async).with(healthy_shard)
        expect(Geo::RepositoryShardSyncWorker).not_to receive(:perform_async).with('broken')

        subject.perform
      end
    end
  end

  def result(success, shard)
    Gitlab::HealthChecks::Result.new(success, nil, { shard: shard })
  end
end
