require 'spec_helper'

describe BuildFinishedWorker do
  describe '#perform' do
    it 'schedules a ChatNotification job for a chat build' do
      build = create(:ci_build, :success, pipeline: create(:ci_pipeline, source: :chat))

      expect(ChatNotificationWorker)
        .to receive(:perform_async)
        .with(build.id)

      described_class.new.perform(build.id)
    end

    it 'does not schedule a ChatNotification job for a regular build' do
      build = create(:ci_build, :success, pipeline: create(:ci_pipeline))

      expect(ChatNotificationWorker)
        .not_to receive(:perform_async)

      described_class.new.perform(build.id)
    end
  end
end
