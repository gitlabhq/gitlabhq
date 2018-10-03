require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::LfsObjectDeletedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :lfs_object_deleted_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:lfs_object_deleted_event) { event_log.lfs_object_deleted_event }
  let(:lfs_object) { lfs_object_deleted_event.lfs_object }

  subject { described_class.new(lfs_object_deleted_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  describe '#process' do
    it 'does not create a tracking database entry' do
      expect { subject.process }.not_to change(Geo::FileRegistry, :count)
    end

    it 'removes the tracking database entry if exist' do
      create(:geo_file_registry, :lfs, file_id: lfs_object.id)

      expect { subject.process }.to change(Geo::FileRegistry.lfs_objects, :count).by(-1)
    end

    it 'schedules a Geo::FileRegistryRemovalWorker job' do
      expect(::Geo::FileRegistryRemovalWorker).to receive(:perform_async).with(:lfs, lfs_object_deleted_event.lfs_object_id)

      subject.process
    end
  end
end
