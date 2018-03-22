require 'spec_helper'

describe Geo::RepositoryVerifySecondaryService, :geo do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  shared_examples 'verify checksums for repositories/wikis' do |type|
    let(:checksum) { instance_double('Gitlab::Git::Checksum') }
    let(:storage) { project.repository_storage }
    let(:relative_path) { service.send(:repository_path) }

    subject(:service)  { described_class.new(registry, type) }

    it 'does not calculate the checksum when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(Gitlab::Git::Checksum).not_to receive(:new).with(storage, relative_path)

      service.execute
    end

    it 'does not verify the checksum if resync is needed' do
      registry.assign_attributes("resync_#{type}" => true)

      expect(Gitlab::Git::Checksum).not_to receive(:new).with(storage, relative_path)

      service.execute
    end

    it 'does not verify the checksum if primary was never verified' do
      repository_state.assign_attributes("#{type}_verification_checksum" => nil)

      expect(Gitlab::Git::Checksum).not_to receive(:new).with(storage, relative_path)

      service.execute
    end

    it 'does not verify the checksum if the checksums already match' do
      repository_state.assign_attributes("#{type}_verification_checksum" => 'my_checksum')
      registry.assign_attributes("#{type}_verification_checksum" => 'my_checksum')

      expect(Gitlab::Git::Checksum).not_to receive(:new).with(storage, relative_path)

      service.execute
    end

    it 'sets checksum when the checksum matches' do
      expect(Gitlab::Git::Checksum).to receive(:new).with(storage, relative_path) { checksum }
      expect(checksum).to receive(:calculate).and_return('my_checksum')

      expect { service.execute }.to change(registry, "#{type}_verification_checksum")
        .from(nil).to('my_checksum')
    end

    it 'keeps track of failure when the checksum mismatch' do
      expect(Gitlab::Git::Checksum).to receive(:new).with(storage, relative_path) { checksum }
      expect(checksum).to receive(:calculate).and_return('other_checksum')

      expect { service.execute }.to change(registry, "last_#{type}_verification_failure")
        .from(nil).to(/#{Regexp.quote(type.to_s.capitalize)} checksum mismatch/)
    end
  end

  describe '#execute' do
    let(:project) { create(:project, :repository, :wiki_repo) }
    let!(:repository_state) { create(:repository_state, project: project, repository_verification_checksum: 'my_checksum', wiki_verification_checksum: 'my_checksum') }
    let(:registry) { create(:geo_project_registry, :synced, project: project) }

    context 'repository' do
      include_examples 'verify checksums for repositories/wikis', :repository
    end

    context 'wiki' do
      include_examples 'verify checksums for repositories/wikis', :wiki
    end
  end
end
