require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::RepositoryRenamedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :renamed_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:repository_renamed_event) { event_log.repository_renamed_event }
  let(:project) {repository_renamed_event.project }
  let(:old_path_with_namespace) { repository_renamed_event.old_path_with_namespace }
  let(:new_path_with_namespace) { repository_renamed_event.new_path_with_namespace }

  subject { described_class.new(repository_renamed_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.fake! { example.run }
  end

  describe '#process' do
    context 'when a tracking entry does not exist' do
      it 'does not create a tracking entry' do
        expect { subject.process }.not_to change(Geo::ProjectRegistry, :count)
      end

      it 'does not schedule a Geo::RenameRepositoryWorker' do
        expect(::Geo::RenameRepositoryWorker).not_to receive(:perform_async)
          .with(project.id, old_path_with_namespace, new_path_with_namespace)

        subject.process
      end
    end

    it 'schedules a Geo::RenameRepositoryWorker' do
      create(:geo_project_registry, project: project)

      expect(::Geo::RenameRepositoryWorker).to receive(:perform_async)
        .with(project.id, old_path_with_namespace, new_path_with_namespace)

      subject.process
    end
  end
end
