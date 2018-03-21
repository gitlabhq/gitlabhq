require 'spec_helper'

describe Geo::RepositoryVerification::Primary::ShardWorker, :postgresql, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:primary) { create(:geo_node, :primary) }
  let(:shard_name) { Gitlab.config.repositories.storages.keys.first }

  before do
    stub_current_geo_node(primary)
  end

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew) { true }

      Gitlab::Geo::ShardHealthCache.update([shard_name])
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for each project' do
      create_list(:project, 2)

      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .to receive(:perform_async).twice

      subject.perform(shard_name)
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for verified projects updated recently' do
      verified_project = create(:project)
      repository_outdated = create(:project)
      wiki_outdated = create(:project)

      create(:repository_state, :repository_verified, :wiki_verified, project: verified_project)
      create(:repository_state, :repository_outdated, project: repository_outdated)
      create(:repository_state, :wiki_outdated, project: wiki_outdated)

      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .not_to receive(:perform_async).with(verified_project.id)
      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .to receive(:perform_async).with(repository_outdated.id)
      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .to receive(:perform_async).with(wiki_outdated.id)

      subject.perform(shard_name)
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects missing repository verification' do
      missing_repository_verification = create(:project)

      create(:repository_state, :wiki_verified, project: missing_repository_verification)

      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .to receive(:perform_async).with(missing_repository_verification.id)

      subject.perform(shard_name)
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects missing wiki verification' do
      missing_wiki_verification = create(:project)

      create(:repository_state, :repository_verified, project: missing_wiki_verification)

      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .to receive(:perform_async).with(missing_wiki_verification.id)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker when shard becomes unhealthy' do
      create(:project)

      Gitlab::Geo::ShardHealthCache.update([])

      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker when not running on a primary' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when number of scheduled jobs exceeds capacity' do
      create(:project)

      is_expected.to receive(:scheduled_job_ids).and_return(1..1000).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker for projects on unhealthy shards' do
      healthy_unverified = create(:project)
      missing_not_verified = create(:project)
      missing_not_verified.update_column(:repository_storage, 'unknown')
      missing_outdated = create(:project)
      missing_outdated.update_column(:repository_storage, 'unknown')

      create(:repository_state, :repository_outdated, project: missing_outdated)

      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .to receive(:perform_async).with(healthy_unverified.id)
      expect(Geo::RepositoryVerification::Primary::SingleWorker)
        .not_to receive(:perform_async).with(missing_not_verified.id)
      expect(Geo::RepositoryVerification::Primary::SingleWorker)
      .not_to receive(:perform_async).with(missing_outdated.id)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end
  end
end
