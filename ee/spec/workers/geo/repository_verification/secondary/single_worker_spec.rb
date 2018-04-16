require 'spec_helper'

describe Geo::RepositoryVerification::Secondary::SingleWorker, :postgresql, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:secondary) { create(:geo_node) }
  let(:project)    { create(:project, :repository, :wiki_repo) }
  let(:registry)   { create(:geo_project_registry, :synced, project: project) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { true }
    end

    it 'does not calculate the checksum when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect_any_instance_of(Geo::RepositoryVerifySecondaryService).not_to receive(:execute)

      subject.perform(registry.id)
    end

    it 'does not calculate the checksum when project is pending deletion' do
      registry.project.update!(pending_delete: true)

      expect_any_instance_of(Geo::RepositoryVerifySecondaryService).not_to receive(:execute)

      subject.perform(registry.id)
    end

    it 'does not raise an error when registry could not be found' do
      expect { subject.perform(-1) }.not_to raise_error
    end

    it 'runs verification for both repository and wiki' do
      create(:repository_state, project: project, repository_verification_checksum: 'my_checksum', wiki_verification_checksum: 'my_checksum')

      expect(Geo::RepositoryVerifySecondaryService).to receive(:new).with(registry, :repository).and_call_original
      expect(Geo::RepositoryVerifySecondaryService).to receive(:new).with(registry, :wiki).and_call_original

      subject.perform(registry.id)
    end
  end
end
