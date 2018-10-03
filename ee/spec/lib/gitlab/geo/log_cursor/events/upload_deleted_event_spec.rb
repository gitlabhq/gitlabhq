require 'spec_helper'

describe Gitlab::Geo::LogCursor::Events::UploadDeletedEvent, :postgresql, :clean_gitlab_redis_shared_state do
  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:project) { create(:project) }
  let(:upload_deleted_event) { create(:geo_upload_deleted_event, project: project) }
  let(:event_log) { create(:geo_event_log, upload_deleted_event: upload_deleted_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }

  subject { described_class.new(upload_deleted_event, Time.now, logger) }

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  describe '#process' do
    context 'with default handling' do
      let(:event_log) { create(:geo_event_log, :upload_deleted_event) }
      let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
      let(:upload_deleted_event) { event_log.upload_deleted_event }
      let(:upload) { upload_deleted_event.upload }

      it 'does not create a tracking database entry' do
        expect { subject.process }.not_to change(Geo::FileRegistry, :count)
      end

      it 'removes the tracking database entry if exist' do
        create(:geo_file_registry, :avatar, file_id: upload.id)

        expect { subject.process }.to change(Geo::FileRegistry.attachments, :count).by(-1)
      end
    end
  end
end
