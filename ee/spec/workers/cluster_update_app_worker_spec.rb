require 'spec_helper'

describe ClusterUpdateAppWorker do
  let(:project) { create(:project) }
  let(:prometheus_update_service) { spy }

  subject { described_class.new }

  around do |example|
    Timecop.freeze(Time.now) { example.run }
  end

  before do
    allow(::Clusters::Applications::PrometheusUpdateService).to receive(:new).and_return(prometheus_update_service)
  end

  describe '#perform' do
    context 'when the application last_update_started_at is higher than the time the job was scheduled in' do
      it 'does nothing' do
        application = create(:clusters_applications_prometheus, :updated, last_update_started_at: Time.now)

        expect(prometheus_update_service).not_to receive(:execute)

        expect(subject.perform(application.name, application.id, project.id, Time.now - 5.minutes)).to be_nil
      end
    end

    context 'when another worker is already running' do
      it 'returns nil' do
        application = create(:clusters_applications_prometheus, :updating)

        expect(subject.perform(application.name, application.id, project.id, Time.now)).to be_nil
      end
    end

    it 'executes PrometheusUpdateService' do
      application = create(:clusters_applications_prometheus, :installed)

      expect(prometheus_update_service).to receive(:execute)

      subject.perform(application.name, application.id, project.id, Time.now)
    end
  end
end
