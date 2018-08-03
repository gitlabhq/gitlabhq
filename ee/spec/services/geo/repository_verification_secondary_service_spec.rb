require 'spec_helper'

describe Geo::RepositoryVerificationSecondaryService, :geo do
  include ::EE::GeoHelpers

  shared_examples 'verify checksums for repositories/wikis' do |type|
    let(:repository) { find_repository(type) }

    subject(:service)  { described_class.new(registry, type) }

    it 'does not calculate the checksum when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?).and_return(false)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if resync is needed' do
      registry.assign_attributes("resync_#{type}" => true)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if primary was never verified' do
      repository_state.assign_attributes("#{type}_verification_checksum" => nil)

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'does not verify the checksum if the current checksum matches' do
      repository_state.assign_attributes("#{type}_verification_checksum" => 'my_checksum')
      registry.assign_attributes("#{type}_verification_checksum_sha" => 'my_checksum')

      expect(repository).not_to receive(:checksum)

      service.execute
    end

    it 'sets checksum when the checksum matches' do
      allow(repository).to receive(:checksum).and_return('my_checksum')

      service.execute

      expect(registry).to have_attributes(
        "#{type}_verification_checksum_sha" => 'my_checksum',
        "#{type}_checksum_mismatch" => false,
        "last_#{type}_verification_failure" => nil,
        "#{type}_verification_retry_count" => nil,
        "resync_#{type}" => false,
        "#{type}_retry_at" => nil,
        "#{type}_retry_count" => nil
      )
    end

    it 'does not mark the verification as failed when there is no repo' do
      allow(repository).to receive(:checksum).and_raise(Gitlab::Git::Repository::NoRepository)

      repository_state.assign_attributes("#{type}_verification_checksum" => '0000000000000000000000000000000000000000')

      service.execute

      expect(registry).to have_attributes(
        "#{type}_verification_checksum_sha" => '0000000000000000000000000000000000000000',
        "#{type}_checksum_mismatch" => false,
        "last_#{type}_verification_failure" => nil,
        "#{type}_verification_retry_count" => nil,
        "resync_#{type}" => false,
        "#{type}_retry_at" => nil,
        "#{type}_retry_count" => nil
      )
    end

    context 'when the checksum mismatch' do
      before do
        allow(repository).to receive(:checksum).and_return('other_checksum')
      end

      it 'keeps track of failures' do
        service.execute

        expect(registry).to have_attributes(
          "#{type}_verification_checksum_sha" => nil,
          "#{type}_checksum_mismatch" => true,
          "last_#{type}_verification_failure" => "#{type.to_s.capitalize} checksum mismatch",
          "#{type}_verification_retry_count" => 1,
          "resync_#{type}" => true,
          "#{type}_retry_at" => be_present,
          "#{type}_retry_count" => 1
        )
      end

      it 'ensures the next retry time is capped properly' do
        registry.update("#{type}_retry_count" => 30)

        service.execute

        expect(registry).to have_attributes(
          "resync_#{type}" => true,
          "#{type}_retry_at" => be_within(100.seconds).of(Time.now + 7.days),
          "#{type}_retry_count" => 31
        )
      end
    end

    context 'when checksum calculation fails' do
      before do
        allow(repository).to receive(:checksum).and_raise("Something went wrong with #{type}")
      end

      it 'keeps track of failures' do
        service.execute

        expect(registry).to have_attributes(
          "#{type}_verification_checksum_sha" => nil,
          "#{type}_checksum_mismatch" => false,
          "last_#{type}_verification_failure" => "Error calculating #{type} checksum",
          "#{type}_verification_retry_count" => 1,
          "resync_#{type}" => true,
          "#{type}_retry_at" => be_present,
          "#{type}_retry_count" => 1
        )
      end

      it 'ensures the next retry time is capped properly' do
        registry.update("#{type}_retry_count" => 30)

        service.execute

        expect(registry).to have_attributes(
          "resync_#{type}" => true,
          "#{type}_retry_at" => be_within(100.seconds).of(Time.now + 7.days),
          "#{type}_retry_count" => 31
        )
      end
    end

    def find_repository(type)
      case type
      when :repository then project.repository
      when :wiki then project.wiki.repository
      end
    end
  end

  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#execute' do
    let(:project) { create(:project, :repository, :wiki_repo) }
    let!(:repository_state) { create(:repository_state, project: project, repository_verification_checksum: 'my_checksum', wiki_verification_checksum: 'my_checksum') }
    let(:registry) { create(:geo_project_registry, :synced, project: project) }

    context 'for a repository' do
      include_examples 'verify checksums for repositories/wikis', :repository
    end

    context 'for a wiki' do
      include_examples 'verify checksums for repositories/wikis', :wiki
    end
  end
end
