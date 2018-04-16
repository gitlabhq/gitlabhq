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

      expect(project_without_repositories.repository).not_to receive(:checksum)

      subject.perform(project_without_repositories.id)
    end

    it 'does not calculate the checksum when project is pending deletion' do
      project_with_repositories.update!(pending_delete: true)

      expect(project_with_repositories.repository).not_to receive(:checksum)

      subject.perform(project_with_repositories.id)
    end

    it 'does not raise an error when project could not be found' do
      expect { subject.perform(-1) }.not_to raise_error
    end

    it 'calculates the checksum for unverified projects' do
      subject.perform(project_with_repositories.id)

      expect(project_with_repositories.repository_state).to have_attributes(
        repository_verification_checksum: instance_of(String),
        last_repository_verification_failure: nil,
        wiki_verification_checksum: instance_of(String),
        last_wiki_verification_failure: nil
      )
    end

    it 'calculates the checksum for outdated projects' do
      repository_state =
        create(:repository_state,
          project: project_with_repositories,
          repository_verification_checksum: nil,
          wiki_verification_checksum: nil)

      subject.perform(project_with_repositories.id)

      repository_state.reload

      expect(repository_state.repository_verification_checksum).not_to be_nil
      expect(repository_state.wiki_verification_checksum).not_to be_nil
    end

    it 'calculates the checksum for outdated repositories' do
      repository_state =
        create(:repository_state,
          project: project_with_repositories,
          repository_verification_checksum: nil,
          wiki_verification_checksum: 'e123')

      subject.perform(project_with_repositories.id)

      repository_state.reload

      expect(repository_state.repository_verification_checksum).not_to be_nil
      expect(repository_state.wiki_verification_checksum).to eq 'e123'
    end

    it 'calculates the checksum for outdated wikis' do
      repository_state =
        create(:repository_state,
          project: project_with_repositories,
          repository_verification_checksum: 'f123',
          wiki_verification_checksum: nil)

      subject.perform(project_with_repositories.id)

      repository_state.reload

      expect(repository_state.repository_verification_checksum).to eq 'f123'
      expect(repository_state.wiki_verification_checksum).not_to be_nil
    end

    it 'does not recalculate the checksum for projects up to date' do
      repository_state =
        create(:repository_state,
          project: project_with_repositories,
          repository_verification_checksum: 'f123',
          wiki_verification_checksum: 'e123')

      subject.perform(project_with_repositories.id)

      expect(repository_state.reload).to have_attributes(
        repository_verification_checksum: 'f123',
        wiki_verification_checksum: 'e123'
      )
    end

    it 'does not calculate the wiki checksum when wiki is not enabled for project' do
      project_with_repositories.update!(wiki_enabled: false)

      subject.perform(project_with_repositories.id)

      expect(project_with_repositories.repository_state).to have_attributes(
        repository_verification_checksum: instance_of(String),
        last_repository_verification_failure: nil,
        wiki_verification_checksum: nil,
        last_wiki_verification_failure: nil
      )
    end

    it 'does not mark the calculating as failed when there is no repo' do
      subject.perform(project_without_repositories.id)

      expect(project_without_repositories.repository_state).to have_attributes(
        repository_verification_checksum: '0000000000000000000000000000000000000000',
        last_repository_verification_failure: nil,
        wiki_verification_checksum: '0000000000000000000000000000000000000000',
        last_wiki_verification_failure: nil
      )
    end

    it 'keeps track of failures when calculating the repository checksum' do
      repository = double

      allow(Repository).to receive(:new).with(
        project_with_repositories.full_path,
        project_with_repositories,
        disk_path: project_with_repositories.disk_path
      ).and_return(repository)

      allow(Repository).to receive(:new).with(
        project_with_repositories.wiki.full_path,
        project_with_repositories,
        disk_path: project_with_repositories.wiki.disk_path,
        is_wiki: true
      ).and_return(repository)

      allow(repository).to receive(:checksum).twice.and_raise('Something went wrong')

      subject.perform(project_with_repositories.id)

      expect(project_with_repositories.repository_state).to have_attributes(
        repository_verification_checksum: nil,
        last_repository_verification_failure: 'Something went wrong',
        wiki_verification_checksum: nil,
        last_wiki_verification_failure: 'Something went wrong'
      )
    end
  end
end
