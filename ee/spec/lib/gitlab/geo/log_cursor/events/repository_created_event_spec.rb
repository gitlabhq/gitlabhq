require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::RepositoryCreatedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:project) { create(:project) }
  let(:repository_created_event) { create(:geo_repository_created_event, project: project) }
  let(:event_log) { create(:geo_event_log, repository_created_event: repository_created_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

  subject { described_class.new(repository_created_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  RSpec.shared_examples 'RepositoryCreatedEvent' do
    it 'creates a new project registry' do
      expect { subject.process }.to change(Geo::ProjectRegistry, :count).by(1)
    end

    it 'sets resync attributes to true' do
      subject.process

      registry = Geo::ProjectRegistry.last
      expect(registry).to have_attributes(project_id: project.id, resync_repository: true, resync_wiki: true)
    end

    it 'sets resync_wiki to false if wiki_path is nil' do
      repository_created_event.update!(wiki_path: nil)

      subject.process

      registry = Geo::ProjectRegistry.last
      expect(registry).to have_attributes(project_id: project.id, resync_repository: true, resync_wiki: false)
    end
  end

  describe '#process' do
    before do
      allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?).with('default').and_return(healthy)
    end

    context 'when the associated shard is healthy' do
      let(:healthy) { true }

      it_behaves_like 'RepositoryCreatedEvent'

      it 'schedules a Geo::ProjectSyncWorker' do
        expect(Geo::ProjectSyncWorker).to receive(:perform_async).with(project.id, anything).once

        subject.process
      end
    end

    context 'when the associated shard is not healthy' do
      let(:healthy) { false }

      it_behaves_like 'RepositoryCreatedEvent'

      it 'does not schedule a Geo::ProjectSyncWorker job' do
        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project.id, anything)

        subject.process
      end
    end
  end
end
