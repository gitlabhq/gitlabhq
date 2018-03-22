require 'spec_helper'

describe Geo::RepositoryVerification::Secondary::ShardWorker, :postgresql, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:secondary) { create(:geo_node) }
  let(:shard_name) { Gitlab.config.repositories.storages.keys.first }

  set(:project) { create(:project) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew) { true }

      Gitlab::Geo::ShardHealthCache.update([shard_name])
    end

    it 'schedule job for each project' do
      other_project = create(:project)
      create(:repository_state, :repository_verified, project: project)
      create(:repository_state, :repository_verified, project: other_project)
      create(:geo_project_registry, :repository_verification_outdated, project: project)
      create(:geo_project_registry, :repository_verification_outdated, project: other_project)

      expect(Geo::RepositoryVerification::Secondary::SingleWorker)
        .to receive(:perform_async).twice

      subject.perform(shard_name)
    end

    it 'schedule job for projects missing repository verification' do
      create(:repository_state, :wiki_verified, project: project)
      missing_repository_verification = create(:geo_project_registry, :wiki_verified, project: project)

      expect(Geo::RepositoryVerification::Secondary::SingleWorker)
        .to receive(:perform_async).with(missing_repository_verification.id)

      subject.perform(shard_name)
    end

    it 'schedule job for projects missing wiki verification' do
      create(:repository_state, :repository_verified, project: project)
      missing_wiki_verification = create(:geo_project_registry, :repository_verified, project: project)

      expect(Geo::RepositoryVerification::Secondary::SingleWorker)
        .to receive(:perform_async).with(missing_wiki_verification.id)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when shard becomes unhealthy' do
      create(:repository_state, project: project)

      Gitlab::Geo::ShardHealthCache.update([])

      expect(Geo::RepositoryVerification::Secondary::SingleWorker)
        .not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::RepositoryVerification::Secondary::SingleWorker)
        .not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not schedule jobs when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect(Geo::RepositoryVerification::Secondary::SingleWorker)
        .not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when number of scheduled jobs exceeds capacity' do
      create(:project)

      is_expected.to receive(:scheduled_job_ids).and_return(1..1000).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end
  end
end
