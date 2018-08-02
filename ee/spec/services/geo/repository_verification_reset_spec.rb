# frozen_string_literal: true

require 'spec_helper'

describe Geo::RepositoryVerificationReset, :geo do
  include ::EE::GeoHelpers

  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#execute' do
    context 'validations' do
      subject { described_class.new(:foo) }

      it 'returns nil when Geo database is not configured' do
        allow(Gitlab::Geo).to receive(:geo_database_configured?).and_return(false)

        expect(subject.execute).to be_nil
      end

      it 'returns nil when not running on a secondary' do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(false)

        expect(subject.execute).to be_nil
      end

      it 'raises an error for an invalid registry type' do
        expect { subject.execute }.to raise_error(ArgumentError, "Invalid type: ':foo'")
      end
    end

    context 'for repositories' do
      subject { described_class.new(:repository) }

      it 'returns the total number of projects marked for resync' do
        create(:geo_project_registry, :synced, :repository_verified)
        create(:geo_project_registry, :synced, :repository_verification_failed)
        create(:geo_project_registry, :synced, :repository_verification_failed)

        expect(subject.execute).to eq 2
      end

      it 'marks projects where verification has failed to be resynced' do
        registry_verification_failed =
          create(:geo_project_registry, :synced, :repository_verification_failed)

        subject.execute

        expect(registry_verification_failed.reload).to have_attributes(
          resync_repository: true,
          repository_verification_checksum_sha: nil,
          repository_checksum_mismatch: false,
          last_repository_verification_failure: nil,
          repository_verification_retry_count: nil,
          repository_missing_on_primary: nil
        )
      end

      it 'marks projects where checksum mismatch to be resynced' do
        registry_checksum_mismatch =
          create(:geo_project_registry, :synced, :repository_checksum_mismatch)

        subject.execute

        expect(registry_checksum_mismatch.reload).to have_attributes(
          resync_repository: true,
          repository_verification_checksum_sha: nil,
          repository_checksum_mismatch: false,
          last_repository_verification_failure: nil,
          repository_verification_retry_count: nil,
          repository_missing_on_primary: nil
        )
      end

      it 'does not mark projects where verification succeeded to be resynced' do
        registry_verification_succeeded =
          create(:geo_project_registry, :synced, :repository_verified)

        subject.execute

        expect(registry_verification_succeeded.reload).to have_attributes(
          resync_repository: false,
          repository_verification_checksum_sha: be_present,
          repository_checksum_mismatch: false,
          last_repository_verification_failure: nil,
          repository_verification_retry_count: nil,
          repository_missing_on_primary: nil
        )
      end

      it 'does not mark projects pending verification to be resynced' do
        registry_pending_verification =
          create(:geo_project_registry, :synced, :repository_verification_outdated)

        subject.execute

        expect(registry_pending_verification.reload).to have_attributes(
          resync_repository: false,
          repository_verification_checksum_sha: nil,
          repository_checksum_mismatch: false,
          last_repository_verification_failure: nil,
          repository_verification_retry_count: nil,
          repository_missing_on_primary: nil
        )
      end
    end

    context 'for wikis' do
      subject { described_class.new(:wiki) }

      it 'returns the total number of projects marked for resync' do
        create(:geo_project_registry, :synced, :wiki_verified)
        create(:geo_project_registry, :synced, :wiki_verification_failed)
        create(:geo_project_registry, :synced, :wiki_verification_failed)

        expect(subject.execute).to eq 2
      end

      it 'marks projects where verification has failed to be resynced' do
        registry_verification_failed =
          create(:geo_project_registry, :synced, :wiki_verification_failed)

        subject.execute

        expect(registry_verification_failed.reload).to have_attributes(
          resync_wiki: true,
          wiki_verification_checksum_sha: nil,
          wiki_checksum_mismatch: false,
          last_wiki_verification_failure: nil,
          wiki_verification_retry_count: nil,
          wiki_missing_on_primary: nil
        )
      end

      it 'marks projects where checksum mismatch to be resynced' do
        registry_checksum_mismatch =
          create(:geo_project_registry, :synced, :wiki_checksum_mismatch)

        subject.execute

        expect(registry_checksum_mismatch.reload).to have_attributes(
          resync_wiki: true,
          wiki_verification_checksum_sha: nil,
          wiki_checksum_mismatch: false,
          last_wiki_verification_failure: nil,
          wiki_verification_retry_count: nil,
          wiki_missing_on_primary: nil
        )
      end

      it 'does not mark projects where verification succeeded to be resynced' do
        registry_verification_succeeded =
          create(:geo_project_registry, :synced, :wiki_verified)

        subject.execute

        expect(registry_verification_succeeded.reload).to have_attributes(
          resync_wiki: false,
          wiki_verification_checksum_sha: be_present,
          wiki_checksum_mismatch: false,
          last_wiki_verification_failure: nil,
          wiki_verification_retry_count: nil,
          wiki_missing_on_primary: nil
        )
      end

      it 'does not mark projects pending verification to be resynced' do
        registry_pending_verification =
          create(:geo_project_registry, :synced, :wiki_verification_outdated)

        subject.execute

        expect(registry_pending_verification.reload).to have_attributes(
          resync_wiki: false,
          wiki_verification_checksum_sha: nil,
          wiki_checksum_mismatch: false,
          last_wiki_verification_failure: nil,
          wiki_verification_retry_count: nil,
          wiki_missing_on_primary: nil
        )
      end
    end
  end
end
