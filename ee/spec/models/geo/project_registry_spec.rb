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

  describe '.checksum_mismatch' do
    it 'returns projects where there is a checksum mismatch' do
      registry_repository_checksum_mismatch = create(:geo_project_registry, :repository_checksum_mismatch)
      regisry_wiki_checksum_mismatch = create(:geo_project_registry, :wiki_checksum_mismatch)
      create(:geo_project_registry)

      expect(described_class.checksum_mismatch).to match_array([regisry_wiki_checksum_mismatch, registry_repository_checksum_mismatch])
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

  context 'redis shared state', :redis do
    after do
      subject.reset_syncs_since_gc!
    end

    describe '#syncs_since_gc' do
      context 'without any sync' do
        it 'returns 0' do
          expect(subject.syncs_since_gc).to eq(0)
        end
      end

      context 'with a number of syncs' do
        it 'returns the number of syncs' do
          2.times { Geo::ProjectHousekeepingService.new(project).increment! }

          expect(subject.syncs_since_gc).to eq(2)
        end
      end
    end

    describe '#increment_syncs_since_gc' do
      it 'increments the number of syncs since the last GC' do
        3.times { subject.increment_syncs_since_gc! }

        expect(subject.syncs_since_gc).to eq(3)
      end
    end

    describe '#reset_syncs_since_gc' do
      it 'resets the number of syncs since the last GC' do
        3.times { subject.increment_syncs_since_gc! }

        subject.reset_syncs_since_gc!

        expect(subject.syncs_since_gc).to eq(0)
      end
    end
  end

  describe '#start_sync!' do
    around do |example|
      Timecop.freeze do
        example.run
      end
    end

    context 'for a repository' do
      let(:type) { 'repository' }

      it 'sets last_repository_synced_at to now' do
        subject.start_sync!(type)

        expect(subject.last_repository_synced_at).to eq(Time.now)
      end

      shared_examples_for 'sets repository_retry_at to a future time' do
        it 'sets repository_retry_at to a future time' do
          subject.start_sync!(type)

          expect(subject.repository_retry_at > Time.now).to be(true)
        end
      end

      context 'when repository_retry_count is nil' do
        it 'sets repository_retry_count to 0' do
          expect do
            subject.start_sync!(type)
          end.to change { subject.repository_retry_count }.from(nil).to(0)
        end

        it_behaves_like 'sets repository_retry_at to a future time'
      end

      context 'when repository_retry_count is 0' do
        before do
          subject.update!(repository_retry_count: 0)
        end

        it 'increments repository_retry_count' do
          expect do
            subject.start_sync!(type)
          end.to change { subject.repository_retry_count }.by(1)
        end

        it_behaves_like 'sets repository_retry_at to a future time'
      end

      context 'when repository_retry_count is 1' do
        before do
          subject.update!(repository_retry_count: 1)
        end

        it 'increments repository_retry_count' do
          expect do
            subject.start_sync!(type)
          end.to change { subject.repository_retry_count }.by(1)
        end

        it_behaves_like 'sets repository_retry_at to a future time'
      end
    end

    context 'for a wiki' do
      let(:type) { 'wiki' }

      it 'sets last_wiki_synced_at to now' do
        subject.start_sync!(type)

        expect(subject.last_wiki_synced_at).to eq(Time.now)
      end

      shared_examples_for 'sets wiki_retry_at to a future time' do
        it 'sets wiki_retry_at to a future time' do
          subject.start_sync!(type)

          expect(subject.wiki_retry_at > Time.now).to be(true)
        end
      end

      context 'when wiki_retry_count is nil' do
        it 'sets wiki_retry_count to 0' do
          expect do
            subject.start_sync!(type)
          end.to change { subject.wiki_retry_count }.from(nil).to(0)
        end

        it_behaves_like 'sets wiki_retry_at to a future time'
      end

      context 'when wiki_retry_count is 0' do
        before do
          subject.update!(wiki_retry_count: 0)
        end

        it 'increments wiki_retry_count' do
          expect do
            subject.start_sync!(type)
          end.to change { subject.wiki_retry_count }.by(1)
        end

        it_behaves_like 'sets wiki_retry_at to a future time'
      end

      context 'when wiki_retry_count is 1' do
        before do
          subject.update!(wiki_retry_count: 1)
        end

        it 'increments wiki_retry_count' do
          expect do
            subject.start_sync!(type)
          end.to change { subject.wiki_retry_count }.by(1)
        end

        it_behaves_like 'sets wiki_retry_at to a future time'
      end
    end
  end

  describe '#finish_sync!' do
    context 'for a repository' do
      let(:type) { 'repository' }

      before do
        subject.start_sync!(type)
        subject.update!(repository_retry_at: 1.day.from_now,
                        force_to_redownload_repository: true,
                        last_repository_sync_failure: 'foo',
                        repository_verification_checksum_sha: 'abc123',
                        repository_checksum_mismatch: true,
                        last_repository_verification_failure: 'bar')
      end

      it 'sets last_repository_successful_sync_at to now' do
        Timecop.freeze do
          subject.finish_sync!(type)

          expect(subject.reload.last_repository_successful_sync_at).to be_within(1).of(Time.now)
        end
      end

      it 'resets sync state' do
        subject.finish_sync!(type)

        expect(subject.reload).to have_attributes(
          resync_repository: false,
          repository_retry_count: be_nil,
          repository_retry_at: be_nil,
          force_to_redownload_repository: false,
          last_repository_sync_failure: be_nil,
          repository_missing_on_primary: false
        )
      end

      it 'resets verification state' do
        subject.finish_sync!(type)

        expect(subject.reload.repository_verification_checksum_sha).to be_nil
        expect(subject.reload.repository_checksum_mismatch).to be false
        expect(subject.reload.last_repository_verification_failure).to be_nil
      end

      context 'when a repository was missing on primary' do
        it 'sets repository_missing_on_primary as true' do
          subject.finish_sync!(type, true)

          expect(subject.reload.repository_missing_on_primary).to be true
        end
      end

      context 'when a repository sync was scheduled after the last sync began' do
        before do
          subject.update!(resync_repository_was_scheduled_at: subject.last_repository_synced_at + 1.minute)

          subject.finish_sync!(type)
        end

        it 'does not reset resync_repository' do
          expect(subject.reload.resync_repository).to be true
        end

        it 'resets the other sync state fields' do
          expect(subject.reload.repository_retry_count).to be_nil
          expect(subject.reload.repository_retry_at).to be_nil
          expect(subject.reload.force_to_redownload_repository).to be false
        end

        it 'resets the verification state' do
          expect(subject.reload.repository_verification_checksum_sha).to be_nil
          expect(subject.reload.repository_checksum_mismatch).to be false
          expect(subject.reload.last_repository_verification_failure).to be_nil
        end
      end
    end

    context 'for a wiki' do
      let(:type) { 'wiki' }

      before do
        subject.start_sync!(type)
        subject.update!(wiki_retry_at: 1.day.from_now,
                        force_to_redownload_wiki: true,
                        last_wiki_sync_failure: 'foo',
                        wiki_verification_checksum_sha: 'abc123',
                        wiki_checksum_mismatch: true,
                        last_wiki_verification_failure: 'bar')
      end

      it 'sets last_wiki_successful_sync_at to now' do
        Timecop.freeze do
          subject.finish_sync!(type)

          expect(subject.reload.last_wiki_successful_sync_at).to be_within(1).of(Time.now)
        end
      end

      it 'resets sync state' do
        subject.finish_sync!(type)

        expect(subject.reload).to have_attributes(
          resync_wiki: false,
          wiki_retry_count: be_nil,
          wiki_retry_at: be_nil,
          force_to_redownload_wiki: false,
          last_wiki_sync_failure: be_nil,
          wiki_missing_on_primary: false
        )
      end

      it 'resets verification state' do
        subject.finish_sync!(type)

        expect(subject.reload.wiki_verification_checksum_sha).to be_nil
        expect(subject.reload.wiki_checksum_mismatch).to be false
        expect(subject.reload.last_wiki_verification_failure).to be_nil
      end

      context 'when a wiki was missing on primary' do
        it 'sets wiki_missing_on_primary as true' do
          subject.finish_sync!(type, true)

          expect(subject.reload.wiki_missing_on_primary).to be true
        end
      end

      context 'when a wiki sync was scheduled after the last sync began' do
        before do
          subject.update!(resync_wiki_was_scheduled_at: subject.last_wiki_synced_at + 1.minute)

          subject.finish_sync!(type)
        end

        it 'does not reset resync_wiki' do
          expect(subject.reload.resync_wiki).to be true
        end

        it 'resets the other sync state fields' do
          expect(subject.reload.wiki_retry_count).to be_nil
          expect(subject.reload.wiki_retry_at).to be_nil
          expect(subject.reload.force_to_redownload_wiki).to be false
        end

        it 'resets the verification state' do
          expect(subject.reload.wiki_verification_checksum_sha).to be_nil
          expect(subject.reload.wiki_checksum_mismatch).to be false
          expect(subject.reload.last_wiki_verification_failure).to be_nil
        end
      end
    end
  end

  describe '#fail_sync!' do
    context 'for a repository' do
      let(:type) { 'repository' }
      let(:message) { 'foo' }
      let(:error) { StandardError.new('bar') }

      before do
        subject.start_sync!(type)
        subject.update!(resync_repository: false,
                        last_repository_sync_failure: 'foo')
      end

      it 'sets resync_repository to true' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.resync_repository).to be true
      end

      it 'includes message in last_repository_sync_failure' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.last_repository_sync_failure).to include(message)
      end

      it 'includes error message in last_repository_sync_failure' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.last_repository_sync_failure).to include(error.message)
      end

      it 'increments repository_retry_count' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.repository_retry_count).to eq(1)
      end

      it 'optionally updates other attributes' do
        subject.fail_sync!(type, message, error, { force_to_redownload_repository: true })

        expect(subject.reload.force_to_redownload_repository).to be true
      end
    end

    context 'for a wiki' do
      let(:type) { 'wiki' }
      let(:message) { 'foo' }
      let(:error) { StandardError.new('bar') }

      before do
        subject.start_sync!(type)
        subject.update!(resync_wiki: false,
                        last_wiki_sync_failure: 'foo')
      end

      it 'sets resync_wiki to true' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.resync_wiki).to be true
      end

      it 'includes message in last_wiki_sync_failure' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.last_wiki_sync_failure).to include(message)
      end

      it 'includes error message in last_wiki_sync_failure' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.last_wiki_sync_failure).to include(error.message)
      end

      it 'increments wiki_retry_count' do
        subject.fail_sync!(type, message, error)

        expect(subject.reload.wiki_retry_count).to eq(1)
      end

      it 'optionally updates other attributes' do
        subject.fail_sync!(type, message, error, { force_to_redownload_wiki: true })

        expect(subject.reload.force_to_redownload_wiki).to be true
      end
    end
  end

  describe '#repository_created!' do
    let(:event) { double(:event, wiki_path: nil) }

    before do
      subject.repository_created!(event)
    end

    it 'sets resync_repository to true' do
      expect(subject.resync_repository).to be true
    end

    context 'when the RepositoryCreatedEvent wiki_path is present' do
      let(:event) { double(:event, wiki_path: 'foo') }

      it 'sets resync_wiki to true' do
        expect(subject.resync_wiki).to be true
      end
    end

    context 'when the RepositoryCreatedEvent wiki_path is blank' do
      it 'sets resync_wiki to false' do
        expect(subject.resync_wiki).to be false
      end
    end
  end

  describe '#repository_updated!' do
    let(:now) { Time.now }

    context 'for a repository' do
      let(:event) { double(:event, source: 'repository') }

      before do
        subject.update!(resync_repository: false,
                        repository_verification_checksum_sha: 'abc123',
                        repository_checksum_mismatch: true,
                        last_repository_verification_failure: 'foo',
                        resync_repository_was_scheduled_at: nil)

        subject.repository_updated!(event, now)
      end

      it 'sets resync_repository to true' do
        expect(subject.resync_repository).to be true
      end

      it 'sets repository_verification_checksum_sha to nil' do
        expect(subject.repository_verification_checksum_sha).to be_nil
      end

      it 'sets repository_checksum_mismatch to false' do
        expect(subject.repository_checksum_mismatch).to be false
      end

      it 'sets last_repository_verification_failure to nil' do
        expect(subject.last_repository_verification_failure).to be_nil
      end

      it 'sets resync_repository_was_scheduled_at to scheduled_at' do
        expect(subject.resync_repository_was_scheduled_at).to eq(now)
      end
    end

    context 'for a wiki' do
      let(:event) { double(:event, source: 'wiki') }

      before do
        subject.update!(resync_wiki: false,
                        wiki_verification_checksum_sha: 'abc123',
                        wiki_checksum_mismatch: true,
                        last_wiki_verification_failure: 'foo',
                        resync_wiki_was_scheduled_at: nil)

        subject.repository_updated!(event, now)
      end

      it 'sets resync_wiki to true' do
        expect(subject.resync_wiki).to be true
      end

      it 'sets wiki_verification_checksum_sha to nil' do
        expect(subject.wiki_verification_checksum_sha).to be_nil
      end

      it 'sets wiki_checksum_mismatch to false' do
        expect(subject.wiki_checksum_mismatch).to be false
      end

      it 'sets last_wiki_verification_failure to nil' do
        expect(subject.last_wiki_verification_failure).to be_nil
      end

      it 'sets resync_wiki_was_scheduled_at to scheduled_at' do
        expect(subject.resync_wiki_was_scheduled_at).to eq(now)
      end
    end
  end
end
