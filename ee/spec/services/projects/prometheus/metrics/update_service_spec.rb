require 'spec_helper'

describe Projects::Prometheus::Metrics::UpdateService do
  let(:metric) { create(:prometheus_metric) }

  it 'updates the prometheus metric' do
    expect do
      described_class.new(metric, { title: "bar" }).execute
    end.to change { metric.reload.title }.to("bar")
  end

  context 'when metric has a prometheus alert associated' do
    let(:schedule_update_service) { spy }

    before do
      create(:prometheus_alert, prometheus_metric: metric)
      allow(::Clusters::Applications::ScheduleUpdateService).to receive(:new).and_return(schedule_update_service)
    end

    context 'when updating title' do
      it 'schedules a prometheus alert update' do
        described_class.new(metric, { title: "bar" }).execute

        expect(schedule_update_service).to have_received(:execute)
      end
    end

    context 'when updating query' do
      it 'schedules a prometheus alert update' do
        described_class.new(metric, { query: "sum(bar)" }).execute

        expect(schedule_update_service).to have_received(:execute)
      end
    end

    it 'does not schedule a prometheus alert update without title nor query being changed' do
      described_class.new(metric, { y_label: "bar" }).execute

      expect(schedule_update_service).not_to have_received(:execute)
    end
  end
end
