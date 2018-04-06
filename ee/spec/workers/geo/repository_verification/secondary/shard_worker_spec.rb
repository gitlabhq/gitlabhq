require 'spec_helper'

describe Geo::RepositoryVerification::Secondary::ShardWorker, :postgresql, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:secondary) { create(:geo_node) }
  let(:shard_name) { Gitlab.config.repositories.storages.keys.first }
  let(:secondary_singleworker) { Geo::RepositoryVerification::Secondary::SingleWorker }

  set(:project) { create(:project) }

  before do
    stub_current_geo_node(secondary)
    allow(Gitlab::Geo::Fdw).to receive(:enabled?).and_return(false)
  end

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:renew) { true }

      Gitlab::Geo::ShardHealthCache.update([shard_name])
    end

    it 'schedules job for each project' do
      other_project = create(:project)
      create(:repository_state, :repository_verified, project: project)
      create(:repository_state, :repository_verified, project: other_project)
      create(:geo_project_registry, :repository_verification_outdated, project: project)
      create(:geo_project_registry, :repository_verification_outdated, project: other_project)

      expect(secondary_singleworker).to receive(:perform_async).twice

      subject.perform(shard_name)
    end

    it 'schedules job for projects missing repository verification' do
      create(:repository_state, :repository_verified, :wiki_verified, project: project)
      missing_repository_verification = create(:geo_project_registry, :wiki_verified, project: project)

      expect(secondary_singleworker).to receive(:perform_async).with(missing_repository_verification.id)

      subject.perform(shard_name)
    end

    it 'schedules job for projects missing wiki verification' do
      create(:repository_state, :repository_verified, :wiki_verified, project: project)
      missing_wiki_verification = create(:geo_project_registry, :repository_verified, project: project)

      expect(secondary_singleworker).to receive(:perform_async).with(missing_wiki_verification.id)

      subject.perform(shard_name)
    end

    # test that when jobs are always moving forward and we're not querying the same things
    # over and over
    describe 'resource loading' do
      before do
        allow(subject).to receive(:db_retrieve_batch_size) { 1 }
      end

      let(:project1_repo_verified) { create(:repository_state, :repository_verified).project }
      let(:project2_repo_verified) { create(:repository_state, :repository_verified).project }
      let(:project3_repo_failed)   { create(:repository_state, :repository_failed).project }
      let(:project4_wiki_verified) { create(:repository_state, :wiki_verified).project }
      let(:project5_both_verified) { create(:repository_state, :repository_verified, :wiki_verified).project }
      let(:project6_both_verified) { create(:repository_state, :repository_verified, :wiki_verified).project }

      it 'handles multiple batches of projects needing verification' do
        reg1 = create(:geo_project_registry, :repository_verification_outdated, project: project1_repo_verified)
        reg2 = create(:geo_project_registry, :repository_verification_outdated, project: project2_repo_verified)

        expect(secondary_singleworker).to receive(:perform_async).with(reg1.id).once

        subject.perform(shard_name)

        reg1.update_attributes!(repository_verification_checksum_sha: project1_repo_verified.repository_state.repository_verification_checksum)

        expect(secondary_singleworker).to receive(:perform_async).with(reg2.id).once

        subject.perform(shard_name)
      end

      it 'handles multiple batches of projects needing verification, skipping failed repos' do
        reg1 = create(:geo_project_registry, :repository_verification_outdated, project: project1_repo_verified)
        reg2 = create(:geo_project_registry, :repository_verification_outdated, project: project2_repo_verified)
        create(:geo_project_registry, :repository_verification_outdated, project: project3_repo_failed)
        reg4 = create(:geo_project_registry, :wiki_verification_outdated, project: project4_wiki_verified)
        create(:geo_project_registry, :repository_verification_failed, :wiki_verification_failed, project: project5_both_verified)
        reg6 = create(:geo_project_registry, project: project6_both_verified)

        expect(secondary_singleworker).to receive(:perform_async).with(reg1.id).once

        subject.perform(shard_name)

        reg1.update_attributes!(repository_verification_checksum_sha: project1_repo_verified.repository_state.repository_verification_checksum)

        expect(secondary_singleworker).to receive(:perform_async).with(reg2.id).once

        subject.perform(shard_name)

        reg2.update_attributes!(repository_verification_checksum_sha: project2_repo_verified.repository_state.repository_verification_checksum)

        expect(secondary_singleworker).to receive(:perform_async).with(reg4.id).once

        subject.perform(shard_name)

        reg4.update_attributes!(last_wiki_verification_failure: 'Failed!')

        expect(secondary_singleworker).to receive(:perform_async).with(reg6.id).once

        subject.perform(shard_name)
      end
    end

    it 'does not schedule jobs when shard becomes unhealthy' do
      create(:repository_state, project: project)

      Gitlab::Geo::ShardHealthCache.update([])

      expect(secondary_singleworker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(secondary_singleworker).not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not schedule jobs when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect(secondary_singleworker).not_to receive(:perform_async)

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
