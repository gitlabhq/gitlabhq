require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::RepositoryDeletedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :deleted_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:repository_deleted_event) { event_log.repository_deleted_event }
  let(:project) { repository_deleted_event.project }
  let(:deleted_project_name) { repository_deleted_event.deleted_project_name }
  let(:deleted_path) { repository_deleted_event.deleted_path }

  subject { described_class.new(repository_deleted_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  describe '#process' do
    context 'when a tracking entry does not exist' do
      it 'does not schedule a GeoRepositoryDestroyWorker' do
        expect(::GeoRepositoryDestroyWorker).not_to receive(:perform_async)
          .with(project.id, deleted_project_name, deleted_path, project.repository_storage)

        subject.process
      end

      it 'does not create a tracking entry' do
        expect { subject.process }.not_to change(Geo::ProjectRegistry, :count)
      end
    end

    context 'when a tracking entry exists' do
      let!(:tracking_entry) { create(:geo_project_registry, project: project) }

      it 'removes the tracking entry' do
        expect { subject.process }.to change(Geo::ProjectRegistry, :count).by(-1)
      end

      context 'when selective sync is enabled' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [project.namespace]) }

        it 'replays delete events when project does not exist on primary' do
          project.delete

          expect(::GeoRepositoryDestroyWorker).to receive(:perform_async)
          .with(project.id, deleted_project_name, deleted_path, project.repository_storage)

          subject.process
        end
      end
    end
  end
end
