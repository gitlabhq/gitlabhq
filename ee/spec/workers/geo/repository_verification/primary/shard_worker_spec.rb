require 'spec_helper'

describe Geo::RepositoryVerification::Primary::ShardWorker, :postgresql, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:primary)   { create(:geo_node, :primary) }
  let(:shard_name) { Gitlab.config.repositories.storages.keys.first }
  let(:primary_singleworker) { Geo::RepositoryVerification::Primary::SingleWorker }

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

      expect(primary_singleworker).to receive(:perform_async).twice

      subject.perform(shard_name)
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for verified projects updated recently' do
      verified_project = create(:project)
      repository_outdated = create(:project)
      wiki_outdated = create(:project)

      create(:repository_state, :repository_verified, :wiki_verified, project: verified_project)
      create(:repository_state, :repository_outdated, project: repository_outdated)
      create(:repository_state, :wiki_outdated, project: wiki_outdated)

      expect(primary_singleworker).not_to receive(:perform_async).with(verified_project.id)
      expect(primary_singleworker).to receive(:perform_async).with(repository_outdated.id)
      expect(primary_singleworker).to receive(:perform_async).with(wiki_outdated.id)

      subject.perform(shard_name)
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects missing repository verification' do
      missing_repository_verification = create(:project)

      create(:repository_state, :wiki_verified, project: missing_repository_verification)

      expect(primary_singleworker).to receive(:perform_async).with(missing_repository_verification.id)

      subject.perform(shard_name)
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects missing wiki verification' do
      missing_wiki_verification = create(:project)

      create(:repository_state, :repository_verified, project: missing_wiki_verification)

      expect(primary_singleworker).to receive(:perform_async).with(missing_wiki_verification.id)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker when shard becomes unhealthy' do
      create(:project)

      Gitlab::Geo::ShardHealthCache.update([])

      expect(primary_singleworker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker when not running on a primary' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect(primary_singleworker).not_to receive(:perform_async)

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

      expect(primary_singleworker).to receive(:perform_async).with(healthy_unverified.id)
      expect(primary_singleworker).not_to receive(:perform_async).with(missing_not_verified.id)
      expect(primary_singleworker).not_to receive(:perform_async).with(missing_outdated.id)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    # test that jobs are always moving forward and we're not querying the same things
    # over and over
    describe 'resource loading' do
      before do
        allow(subject).to receive(:db_retrieve_batch_size) { 1 }
      end

      let(:project_repo_verified)   { create(:repository_state, :repository_verified).project }
      let(:project_repo_failed)     { create(:repository_state, :repository_failed).project }
      let(:project_wiki_verified)   { create(:repository_state, :wiki_verified).project }
      let(:project_wiki_failed)     { create(:repository_state, :wiki_failed).project }
      let(:project_both_verified)   { create(:repository_state, :repository_verified, :wiki_verified).project }
      let(:project_both_failed)     { create(:repository_state, :repository_failed, :wiki_failed).project }
      let(:project_repo_unverified) { create(:repository_state).project }
      let(:project_wiki_unverified) { create(:repository_state).project }

      it 'handles multiple batches of projects needing verification' do
        project1 = project_repo_unverified
        project2 = project_wiki_unverified

        expect(primary_singleworker).to receive(:perform_async).with(project1.id).once

        subject.perform(shard_name)

        project1.repository_state.update_attributes!(
          repository_verification_checksum: 'f079a831cab27bcda7d81cd9b48296d0c3dd92ee',
          wiki_verification_checksum: 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef')

        expect(primary_singleworker).to receive(:perform_async).with(project2.id).once

        subject.perform(shard_name)
      end

      it 'handles multiple batches of projects needing verification, skipping failed repos' do
        project1 = project_repo_unverified
        project2 = project_wiki_unverified
        project3 = project_both_failed      # rubocop:disable Lint/UselessAssignment
        project4 = project_repo_verified
        project5 = project_wiki_verified

        expect(primary_singleworker).to receive(:perform_async).with(project1.id).once

        subject.perform(shard_name)

        project1.repository_state.update_attributes!(
          repository_verification_checksum: 'f079a831cab27bcda7d81cd9b48296d0c3dd92ee',
          wiki_verification_checksum: 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef')

        expect(primary_singleworker).to receive(:perform_async).with(project2.id).once

        subject.perform(shard_name)

        project2.repository_state.update_attributes!(
          repository_verification_checksum: 'f079a831cab27bcda7d81cd9b48296d0c3dd92ee',
          wiki_verification_checksum: 'e079a831cab27bcda7d81cd9b48296d0c3dd92ef')

        expect(primary_singleworker).to receive(:perform_async).with(project4.id).once

        subject.perform(shard_name)

        project4.repository_state.update_attributes!(last_wiki_verification_failure: 'Failed!')

        expect(primary_singleworker).to receive(:perform_async).with(project5.id).once

        subject.perform(shard_name)
      end
    end
  end
end
