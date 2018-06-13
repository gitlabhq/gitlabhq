require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::RepositoryUpdatedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers

  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  set(:secondary) { create(:geo_node) }
  let(:project) { create(:project) }
  let(:repository_updated_event) { create(:geo_repository_updated_event, project: project) }
  let(:event_log) { create(:geo_event_log, repository_updated_event: repository_updated_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

  subject { described_class.new(repository_updated_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  before do
    stub_current_geo_node(secondary)
    allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?).with('broken').and_return(false)
  end

  RSpec.shared_examples 'RepositoryUpdatedEvent' do
    it 'creates a new project registry if it does not exist' do
      expect { subject.process }.to change(Geo::ProjectRegistry, :count).by(1)
    end

    context 'when we have an event source' do
      before do
        repository_updated_event.update!(source: event_source)
      end

      context 'when event source is a repository' do
        let(:event_source) { Geo::RepositoryUpdatedEvent::REPOSITORY }
        let!(:registry) { create(:geo_project_registry, :synced, :repository_verified, :repository_checksum_mismatch, project: repository_updated_event.project) }

        it 'sets resync_repository to true' do
          subject.process
          reloaded_registry = registry.reload

          expect(reloaded_registry.resync_repository).to be true
        end

        it 'resets the repository verification fields' do
          subject.process
          reloaded_registry = registry.reload

          expect(reloaded_registry).to have_attributes(
            repository_verification_checksum_sha: nil,
            repository_checksum_mismatch: false,
            last_repository_verification_failure: nil
          )
        end

        it 'sets resync_repository_was_scheduled_at to the scheduled time' do
          Timecop.freeze do
            subject.process
            reloaded_registry = registry.reload

            expect(reloaded_registry.resync_repository_was_scheduled_at).to be_within(1.second).of(Time.now)
          end
        end
      end

      context 'when the event source is a wiki' do
        let(:event_source) { Geo::RepositoryUpdatedEvent::WIKI }
        let!(:registry) { create(:geo_project_registry, :synced, :wiki_verified, :wiki_checksum_mismatch, project: repository_updated_event.project) }

        it 'sets resync_wiki to true' do
          subject.process
          reloaded_registry = registry.reload

          expect(reloaded_registry.resync_wiki).to be true
        end

        it 'resets the wiki repository verification fields' do
          subject.process
          reloaded_registry = registry.reload

          expect(reloaded_registry.wiki_verification_checksum_sha).to be_nil
          expect(reloaded_registry.wiki_checksum_mismatch).to be false
          expect(reloaded_registry.last_wiki_verification_failure).to be_nil
        end

        it 'sets resync_wiki_was_scheduled_at to the scheduled time' do
          Timecop.freeze do
            subject.process
            reloaded_registry = registry.reload

            expect(reloaded_registry.resync_wiki_was_scheduled_at).to be_within(1.second).of(Time.now)
          end
        end
      end
    end
  end

  describe '#process' do
    let(:now) { Time.now }

    before do
      allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?).with('default').and_return(healthy)
    end

    context 'when the associated shard is healthy' do
      let(:healthy) { true }

      it_behaves_like 'RepositoryUpdatedEvent'

      it 'schedules a Geo::ProjectSyncWorker' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async).with(project.id, now).once

        Timecop.freeze(now) { subject.process }
      end
    end

    context 'when associated shard is unhealthy' do
      let(:healthy) { false }

      it_behaves_like 'RepositoryUpdatedEvent'

      it 'does not schedule a Geo::ProjectSyncWorker job' do
        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project.id, now)

        Timecop.freeze(now) { subject.process }
      end
    end
  end
end
