require 'spec_helper'

describe Geo::TruncateEventLogWorker, :geo do
  include ::EE::GeoHelpers

  subject(:worker) { described_class.new }
  set(:primary) { create(:geo_node, :primary) }

  describe '#perform' do
    context 'current node primary' do
      before do
        stub_current_geo_node(primary)
      end

      it 'deletes everything from the Geo event log' do
        create_list(:geo_event_log, 2)

        expect(ActiveRecord::Base.connection).to receive(:truncate).with('geo_event_log').and_call_original

        expect { worker.perform }.to change { Geo::EventLog.count }.by(-2)
      end

      it 'deletes nothing when a secondary node exists' do
        create(:geo_node)
        create_list(:geo_event_log, 2)

        expect { worker.perform }.not_to change { Geo::EventLog.count }
      end
    end
  end
end
