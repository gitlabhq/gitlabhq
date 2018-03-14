require 'spec_helper'

describe Geo::ProjectRegistry do
  using RSpec::Parameterized::TableSyntax

  set(:project) { create(:project) }
  set(:registry) { create(:geo_project_registry, project_id: project.id) }

  subject { registry }

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:project) }
  end

  describe '.failed_repos' do
    it 'returns projects where last attempt to sync failed' do
      create(:geo_project_registry, :synced)
      create(:geo_project_registry, :synced, :dirty)
      create(:geo_project_registry, :repository_syncing)
      create(:geo_project_registry, :wiki_syncing)
      create(:geo_project_registry, :wiki_sync_failed)

      repository_sync_failed = create(:geo_project_registry, :repository_sync_failed)

      expect(described_class.failed_repos).to match_array([repository_sync_failed])
    end
  end

  describe '.failed_wikis' do
    it 'returns projects where last attempt to sync failed' do
      create(:geo_project_registry, :synced)
      create(:geo_project_registry, :synced, :dirty)
      create(:geo_project_registry, :repository_syncing)
      create(:geo_project_registry, :wiki_syncing)
      create(:geo_project_registry, :repository_sync_failed)

      wiki_sync_failed = create(:geo_project_registry, :wiki_sync_failed)

      expect(described_class.failed_wikis).to match_array([wiki_sync_failed])
    end
  end

  describe '.verified_repos' do
    it 'returns projects that verified' do
      create(:geo_project_registry, :repository_verification_failed)
      create(:geo_project_registry, :wiki_verified)
      create(:geo_project_registry, :wiki_verification_failed)

      repository_verified = create(:geo_project_registry, :repository_verified)

      expect(described_class.verified_repos).to match_array([repository_verified])
    end
  end

  describe '.verification_failed_repos' do
    it 'returns projects where last attempt to verify failed' do
      create(:geo_project_registry, :repository_verified)
      create(:geo_project_registry, :wiki_verified)
      create(:geo_project_registry, :wiki_verification_failed)

      repository_verification_failed = create(:geo_project_registry, :repository_verification_failed)

      expect(described_class.verification_failed_repos).to match_array([repository_verification_failed])
    end
  end

  describe '.verified_wikis' do
    it 'returns projects that verified' do
      create(:geo_project_registry, :repository_verification_failed)
      create(:geo_project_registry, :repository_verified)
      create(:geo_project_registry, :wiki_verification_failed)

      wiki_verified = create(:geo_project_registry, :wiki_verified)

      expect(described_class.verified_wikis).to match_array([wiki_verified])
    end
  end

  describe '.verification_failed_wikis' do
    it 'returns projects where last attempt to verify failed' do
      create(:geo_project_registry, :repository_verified)
      create(:geo_project_registry, :wiki_verified)
      create(:geo_project_registry, :repository_verification_failed)

      wiki_verification_failed = create(:geo_project_registry, :wiki_verification_failed)

      expect(described_class.verification_failed_wikis).to match_array([wiki_verification_failed])
    end
  end

  describe '.retry_due' do
    it 'returns projects that should be synced' do
      create(:geo_project_registry, repository_retry_at: Date.yesterday, wiki_retry_at: Date.yesterday)
      tomorrow = create(:geo_project_registry, repository_retry_at: Date.tomorrow, wiki_retry_at: Date.tomorrow)
      create(:geo_project_registry)

      expect(described_class.retry_due).not_to include(tomorrow)
    end
  end

  describe '#repository_sync_due?' do
    where(:resync_repository, :last_successful_sync, :last_sync, :expected) do
      now = Time.now
      past = now - 1.year
      future = now + 1.year

      true  | nil | nil | true
      true  | now | nil | true
      false | nil | nil | true
      false | now | nil | false

      true  | nil | past | true
      true  | now | past | true
      false | nil | past | true
      false | now | past | false

      true  | nil | future | true
      true  | now | future | false
      false | nil | future | true
      false | now | future | false
    end

    with_them do
      before do
        registry.update!(resync_repository: resync_repository, last_repository_successful_sync_at: last_successful_sync, last_repository_synced_at: last_sync)
      end

      subject { registry.repository_sync_due?(Time.now) }

      it { is_expected.to eq(expected) }
    end
  end

  describe '#wiki_sync_due?' do
    where(:resync_wiki, :last_successful_sync, :last_sync, :expected) do
      now = Time.now
      past = now - 1.year
      future = now + 1.year

      true  | nil | nil | true
      true  | now | nil | true
      false | nil | nil | true
      false | now | nil | false

      true  | nil | past | true
      true  | now | past | true
      false | nil | past | true
      false | now | past | false

      true  | nil | future | true
      true  | now | future | false
      false | nil | future | true
      false | now | future | false
    end

    with_them do
      before do
        registry.update!(resync_wiki: resync_wiki, last_wiki_successful_sync_at: last_successful_sync, last_wiki_synced_at: last_sync)
      end

      subject { registry.wiki_sync_due?(Time.now) }

      context 'wiki enabled' do
        it { is_expected.to eq(expected) }
      end

      context 'wiki disabled' do
        before do
          project.update!(wiki_enabled: false)
        end

        it { is_expected.to be_falsy }
      end
    end
  end
end
