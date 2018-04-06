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

  describe '.synced_repos' do
    it 'returns clean projects where last attempt to sync succeeded' do
      expected = []
      expected << create(:geo_project_registry, :synced)
      create(:geo_project_registry, :synced, :dirty)
      create(:geo_project_registry, :repository_syncing)
      expected << create(:geo_project_registry, :wiki_syncing)
      expected << create(:geo_project_registry, :wiki_sync_failed)
      create(:geo_project_registry, :repository_sync_failed)

      expect(described_class.synced_repos).to match_array(expected)
    end
  end

  describe '.synced_wikis' do
    it 'returns clean projects where last attempt to sync succeeded' do
      expected = []
      expected << create(:geo_project_registry, :synced)
      create(:geo_project_registry, :synced, :dirty)
      expected << create(:geo_project_registry, :repository_syncing)
      create(:geo_project_registry, :wiki_syncing)
      create(:geo_project_registry, :wiki_sync_failed)
      expected << create(:geo_project_registry, :repository_sync_failed)

      expect(described_class.synced_wikis).to match_array(expected)
    end
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
    where(:last_synced_at, :resync, :retry_at, :expected) do
      now = Time.now
      past = now - 1.year
      future = now + 1.year

      nil    | false | nil    | true
      nil    | true  | nil    | true
      nil    | true  | past   | true
      nil    | true  | future | true

      past   | false | nil    | false
      past   | true  | nil    | true
      past   | true  | past   | true
      past   | true  | future | false

      future | false | nil    | false
      future | true  | nil    | false
      future | true  | past   | false
      future | true  | future | false
    end

    with_them do
      before do
        registry.update!(
          last_repository_synced_at: last_synced_at,
          resync_repository: resync,
          repository_retry_at: retry_at
        )
      end

      it { expect(registry.repository_sync_due?(Time.now)).to eq(expected) }
    end
  end

  describe '#wiki_sync_due?' do
    where(:last_synced_at, :resync, :retry_at, :expected) do
      now = Time.now
      past = now - 1.year
      future = now + 1.year

      nil    | false | nil    | true
      nil    | true  | nil    | true
      nil    | true  | past   | true
      nil    | true  | future | true

      past   | false | nil    | false
      past   | true  | nil    | true
      past   | true  | past   | true
      past   | true  | future | false

      future | false | nil    | false
      future | true  | nil    | false
      future | true  | past   | false
      future | true  | future | false
    end

    with_them do
      before do
        registry.update!(
          last_wiki_synced_at: last_synced_at,
          resync_wiki: resync,
          wiki_retry_at: retry_at
        )
      end

      context 'wiki enabled' do
        it { expect(registry.wiki_sync_due?(Time.now)).to eq(expected) }
      end

      context 'wiki disabled' do
        before do
          project.update!(wiki_enabled: false)
        end

        it { expect(registry.wiki_sync_due?(Time.now)).to be_falsy }
      end
    end
  end
end
