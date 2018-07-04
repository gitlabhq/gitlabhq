require 'spec_helper'

describe Geo::RepositoryVerification::Primary::BatchWorker, :postgresql, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  set(:healthy_not_verified) { create(:project) }

  let!(:primary) { create(:geo_node, :primary) }
  let(:healthy_shard) { healthy_not_verified.repository.storage }

  before do
    stub_current_geo_node(primary)
  end

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  describe '#perform' do
    it 'skips backfill for repositories on other shards' do
      create(:project, repository_storage: 'broken')
      unhealthy_outdated = create(:project, repository_storage: 'broken')

      create(:repository_state, :repository_outdated, project: unhealthy_outdated)

      allow(Gitlab::GitalyClient).to receive(:call) do
        raise GRPC::Unavailable.new('No Gitaly available')
      end

      expect(Geo::RepositoryVerification::Primary::ShardWorker).not_to receive(:perform_async).with('broken')

      subject.perform
    end

    it 'skips backfill for projects on missing shards' do
      missing_not_verified = create(:project)
      missing_not_verified.update_column(:repository_storage, 'unknown')
      missing_outdated = create(:project)
      missing_outdated.update_column(:repository_storage, 'unknown')

      create(:repository_state, :repository_outdated, project: missing_outdated)

      # hide the 'broken' storage for this spec
      stub_storage_settings({})

      expect(Geo::RepositoryVerification::Primary::ShardWorker).to receive(:perform_async).with(healthy_shard)
      expect(Geo::RepositoryVerification::Primary::ShardWorker).not_to receive(:perform_async).with('unknown')

      subject.perform
    end

    it 'skips backfill for projects with downed Gitaly server' do
      create(:project, repository_storage: 'broken')
      unhealthy_outdated = create(:project, repository_storage: 'broken')

      create(:repository_state, :repository_outdated, project: unhealthy_outdated)

      # Report only one healthy shard
      expect(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness)
        .and_return([result(true, healthy_shard), result(false, 'broken')])

      expect(Geo::RepositoryVerification::Primary::ShardWorker).to receive(:perform_async).with(healthy_shard)
      expect(Geo::RepositoryVerification::Primary::ShardWorker).not_to receive(:perform_async).with('broken')

      subject.perform
    end

    context 'when geo_repository_verification is disabled' do
      it 'does not schedule jobs' do
        allow(Gitlab::Geo).to receive(:repository_verification_enabled?).and_return(false)

        expect(Geo::RepositoryVerification::Primary::ShardWorker)
          .not_to receive(:perform_async).with(healthy_shard)

        subject.perform
      end
    end
  end

  def result(success, shard)
    Gitlab::HealthChecks::Result.new(success, nil, { shard: shard })
  end
end
