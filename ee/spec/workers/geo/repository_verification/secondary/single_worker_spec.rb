require 'spec_helper'

describe Geo::RepositoryVerification::Secondary::SingleWorker, :postgresql, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let!(:secondary) { create(:geo_node) }
  let(:project)    { create(:project, :repository, :wiki_repo) }
  let(:registry)   { create(:geo_project_registry, :synced, project: project) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#perform' do
    it 'does not calculate the checksum when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      subject.perform(registry.id)

      expect(registry.reload).to have_attributes(
        repository_verification_checksum_sha: nil,
        last_repository_verification_failure: nil,
        wiki_verification_checksum_sha: nil,
        last_wiki_verification_failure: nil
      )
    end

    it 'does not calculate the checksum when project is pending deletion' do
      registry.project.update!(pending_delete: true)

      subject.perform(registry.id)

      expect(registry.reload).to have_attributes(
        repository_verification_checksum_sha: nil,
        last_repository_verification_failure: nil,
        wiki_verification_checksum_sha: nil,
        last_wiki_verification_failure: nil
      )
    end

    it 'does not raise an error when registry could not be found' do
      expect { subject.perform(-1) }.not_to raise_error
    end

    it 'does not raise an error when project could not be found' do
      registry.update_column(:project_id, -1)

      expect { subject.perform(registry.id) }.not_to raise_error
    end

    it 'runs verification for both repository and wiki' do
      stub_exclusive_lease

      service =
        instance_double(Geo::RepositoryVerificationSecondaryService, execute: true)

      allow(Geo::RepositoryVerificationSecondaryService)
        .to receive(:new)
        .with(registry, :repository)
        .and_return(service)

      allow(Geo::RepositoryVerificationSecondaryService)
        .to receive(:new)
        .with(registry, :wiki)
        .and_return(service)

      subject.perform(registry.id)

      expect(service).to have_received(:execute).twice
    end
  end
end
