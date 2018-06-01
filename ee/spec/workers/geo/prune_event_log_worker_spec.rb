require 'spec_helper'

describe Geo::PruneEventLogWorker, :geo do
  include ::EE::GeoHelpers

  subject(:worker) { described_class.new }
  set(:primary) { create(:geo_node, :primary) }
  set(:secondary) { create(:geo_node) }

  before do
    allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain).and_return(true)
  end

  describe '#perform' do
    context 'current node secondary' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'does nothing' do
        expect(worker).not_to receive(:try_obtain_lease)

        worker.perform
      end
    end

    context 'current node primary' do
      before do
        stub_current_geo_node(primary)
      end

      it 'logs error when it cannot obtain lease' do
        allow_any_instance_of(Gitlab::ExclusiveLease).to receive(:try_obtain) { nil }

        expect(worker).to receive(:log_error).with(/^Cannot obtain an exclusive lease/)

        worker.perform
      end

      context 'no secondary nodes' do
        before do
          secondary.destroy
        end

        it 'deletes everything from the Geo event log' do
          create_list(:geo_event_log, 2)

          expect(Geo::TruncateEventLogWorker).to receive(:perform_in).with(described_class::TRUNCATE_DELAY)

          worker.perform
        end
      end

      context 'multiple secondary nodes' do
        set(:secondary2) { create(:geo_node) }
        let(:healthy_status) { build(:geo_node_status, :healthy) }
        let(:unhealthy_status) { build(:geo_node_status, :unhealthy) }

        it 'contacts all secondary nodes for their status' do
          status = spy(:status)

          allow_any_instance_of(GeoNode).to receive(:status).and_return(status)

          expect(status).to receive(:cursor_last_event_id).twice.and_return(0)

          worker.perform
        end

        it 'aborts when there are unhealthy nodes' do
          events = create_list(:geo_event_log, 2)

          create(:geo_node_status, :healthy, cursor_last_event_id: events.last.id, geo_node_id: secondary.id)
          create(:geo_node_status, :unhealthy, geo_node_id: secondary2.id)

          expect(worker).to receive(:log_info).with(/^Could not get status of all nodes/, unhealthy_node_count: 1)

          expect { worker.perform }.not_to change { Geo::EventLog.count }
        end

        it 'takes the integer-minimum value of all cursor_last_event_ids' do
          events = create_list(:geo_event_log, 5)

          create(:geo_node_status, :healthy, cursor_last_event_id: events[3].id, geo_node_id: secondary.id)
          create(:geo_node_status, :healthy, cursor_last_event_id: events.last.id, geo_node_id: secondary2.id)
          expect(worker).to receive(:log_info).with(/^Delete Geo Event Log/, geo_event_log_id: events[3].id)

          expect { worker.perform }.to change { Geo::EventLog.count }.by(-4)
        end
      end
    end
  end

  describe '#log_error' do
    it 'calls the Geo logger' do
      expect(Gitlab::Geo::Logger).to receive(:error)

      worker.log_error('Something is wrong')
    end
  end
end
