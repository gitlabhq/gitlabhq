require 'spec_helper'

describe Clusters::Applications::ScheduleUpdateService do
  describe '#execute' do
    let(:project) { create(:project) }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'when application is able to be updated' do
      context 'when the application was recently scheduled' do
        it 'schedules worker with a backoff delay' do
          application = create(:clusters_applications_prometheus, :installed, last_update_started_at: Time.now + 5.minutes)
          service = described_class.new(application, project)

          expect(::ClusterUpdateAppWorker).to receive(:perform_in).with(described_class::BACKOFF_DELAY, application.name, application.id, project.id, Time.now).once

          service.execute
        end
      end

      context 'when the application has not been recently updated' do
        it 'schedules worker' do
          application = create(:clusters_applications_prometheus, :installed)
          service = described_class.new(application, project)

          expect(::ClusterUpdateAppWorker).to receive(:perform_async).with(application.name, application.id, project.id, Time.now).once

          service.execute
        end
      end
    end
  end
end
