require 'spec_helper'

describe Geo::RepositorySyncWorker, :geo, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:primary) { create(:geo_node, :primary) }
  let!(:secondary) { create(:geo_node) }
  let!(:synced_group) { create(:group) }
  let!(:project_in_synced_group) { create(:project, group: synced_group) }
  let!(:unsynced_project) { create(:project) }

  subject { described_class.new }

  before do
    stub_current_geo_node(secondary)
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

        Sidekiq::Testing.inline! { subject.perform }
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

        Sidekiq::Testing.inline! { subject.perform }
      end

      it 'skips backfill for projects with downed Gitaly server' do
        create(:project, group: synced_group, repository_storage: 'broken')
        unhealthy_dirty = create(:project, group: synced_group, repository_storage: 'broken')
        healthy_shard = project_in_synced_group.repository.storage

        create(:geo_project_registry, :synced, :repository_dirty, project: unhealthy_dirty)

        # Report only one healthy shard
        allow(Gitlab::HealthChecks::FsShardsCheck).to receive(:readiness).and_return(
          [Gitlab::HealthChecks::Result.new(true, nil, { shard: healthy_shard }),
           Gitlab::HealthChecks::Result.new(true, nil, { shard: 'broken' })])
        allow(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness).and_return(
          [Gitlab::HealthChecks::Result.new(true, nil, { shard: healthy_shard }),
           Gitlab::HealthChecks::Result.new(false, nil, { shard: 'broken' })])

        expect(Geo::RepositoryShardSyncWorker).to receive(:perform_async).with(healthy_shard)
        expect(Geo::RepositoryShardSyncWorker).not_to receive(:perform_async).with('broken')

        Sidekiq::Testing.inline! { subject.perform }
      end
    end
  end
end
