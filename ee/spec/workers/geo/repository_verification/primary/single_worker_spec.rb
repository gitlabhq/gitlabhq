require 'spec_helper'

describe Geo::RepositoryVerification::Primary::SingleWorker, :postgresql, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  set(:project_with_repositories) { create(:project, :repository, :wiki_repo) }
  set(:project_without_repositories) { create(:project) }

  let!(:primary) { create(:geo_node, :primary) }

  before do
    stub_current_geo_node(primary)
  end

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
    end

    it 'does not calculate the checksum when not running on a primary' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect_any_instance_of(Gitlab::Git::Checksum).not_to receive(:calculate)

      subject.perform(project_without_repositories.id, Time.now)
    end

    it 'does not calculate the checksum when project is pending deletion' do
      project_with_repositories.update!(pending_delete: true)

      expect_any_instance_of(Gitlab::Git::Checksum).not_to receive(:calculate)

      subject.perform(project_with_repositories.id, Time.now)
    end

    it 'does not raise an error when project could not be found' do
      expect { subject.perform(-1, Time.now) }.not_to raise_error
    end

    it 'calculates the checksum for unverified projects' do
      subject.perform(project_with_repositories.id, Time.now)

      expect(project_with_repositories.repository_state).to have_attributes(
        repository_verification_checksum: instance_of(String),
        last_repository_verification_failure: nil,
        last_repository_verification_at: instance_of(Time),
        last_repository_verification_failed: false,
        wiki_verification_checksum: instance_of(String),
        last_wiki_verification_failure: nil,
        last_wiki_verification_at: instance_of(Time),
        last_wiki_verification_failed: false
      )
    end

    it 'calculates the checksum for outdated projects' do
      repository_state =
        create(:repository_state, :repository_verified, :wiki_verified,
          project: project_with_repositories,
          repository_verification_checksum: 'f123',
          last_repository_verification_at: Time.now - 1.hour,
          wiki_verification_checksum: 'e123',
          last_wiki_verification_at: Time.now - 1.hour)

      subject.perform(project_with_repositories.id, Time.now)

      repository_state.reload

      expect(repository_state.repository_verification_checksum).not_to eq 'f123'
      expect(repository_state.last_repository_verification_at).to be_within(10.seconds).of(Time.now)
      expect(repository_state.wiki_verification_checksum).not_to eq 'e123'
      expect(repository_state.last_wiki_verification_at).to be_within(10.seconds).of(Time.now)
    end

    it 'does not recalculate the checksum for projects up to date' do
      last_verification_at = Time.now

      repository_state =
        create(:repository_state, :repository_verified, :wiki_verified,
          project: project_with_repositories,
          repository_verification_checksum: 'f123',
          last_repository_verification_at: last_verification_at,
          wiki_verification_checksum: 'e123',
          last_wiki_verification_at: last_verification_at)

      subject.perform(project_with_repositories.id, Time.now - 1.hour)

      expect(repository_state.reload).to have_attributes(
        repository_verification_checksum: 'f123',
        last_repository_verification_at: be_within(1.second).of(last_verification_at),
        wiki_verification_checksum: 'e123',
        last_wiki_verification_at: be_within(1.second).of(last_verification_at)
      )
    end

    it 'does not calculate the wiki checksum when wiki is not enabled for project' do
      project_with_repositories.update!(wiki_enabled: false)

      subject.perform(project_with_repositories.id, Time.now)

      expect(project_with_repositories.repository_state).to have_attributes(
        repository_verification_checksum: instance_of(String),
        last_repository_verification_failure: nil,
        last_repository_verification_at: instance_of(Time),
        last_repository_verification_failed: false,
        wiki_verification_checksum: nil,
        last_wiki_verification_failure: nil,
        last_wiki_verification_at: nil,
        last_wiki_verification_failed: false
      )
    end

    it 'keeps track of failures when calculating the repository checksum' do
      subject.perform(project_without_repositories.id, Time.now)

      expect(project_without_repositories.repository_state).to have_attributes(
        repository_verification_checksum: nil,
        last_repository_verification_failure: /No repository for such path/,
        last_repository_verification_at: instance_of(Time),
        last_repository_verification_failed: true,
        wiki_verification_checksum: nil,
        last_wiki_verification_failure: /No repository for such path/,
        last_wiki_verification_at: instance_of(Time),
        last_wiki_verification_failed: true
      )
    end
  end
end
