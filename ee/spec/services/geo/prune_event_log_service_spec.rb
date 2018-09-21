# frozen_string_literal: true

require 'spec_helper'

describe Geo::PruneEventLogService do
  include ExclusiveLeaseHelpers

  let(:min_id) { :all }
  let!(:events) { create_list(:geo_event_log, 5, :updated_event) }
  let(:lease_key) { 'geo/prune_event_log_service' }
  let(:lease_timeout) { described_class::LEASE_TIMEOUT }

  subject(:service) { described_class.new(min_id) }

  before do
    stub_exclusive_lease(lease_key, timeout: lease_timeout, renew: true)
  end

  it 'logs error when it cannot obtain lease' do
    stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

    expect(service).to receive(:log_error).with(/^Cannot obtain an exclusive lease/)

    service.execute
  end

  it 'aborts when it cannot renew lease' do
    stub_exclusive_lease(lease_key, timeout: lease_timeout, renew: false)

    expect(service).not_to receive(:prune!)
  end

  it 'prunes all event tables' do
    Geo::EventLog::EVENT_CLASSES.each do |event_class|
      expect(service).to receive(:prune!).with(event_class.constantize, anything)
    end

    service.execute
  end

  it 'prunes max 50k records' do
    expect(service).to receive(:prune!).and_return(20_000).ordered
    expect(service).to receive(:prune!).with(anything, 30_000).and_return(20_000).ordered
    expect(service).to receive(:prune!).with(anything, 10_000).and_return(9_000).ordered
    expect(service).to receive(:prune!).with(anything, 1_000).and_return(1_000).ordered
    expect(service).not_to receive(:prune!).ordered

    service.execute
  end

  context 'event_log_min_id = :all' do
    it 'prunes all events' do
      expect { service.execute }.to change { Geo::EventLog.count }.by(-5)
    end

    it 'prunes all associated events' do
      expect { service.execute }.to change { Geo::RepositoryUpdatedEvent.count }.by(-5)
    end
  end

  context 'with event_log_min_id' do
    let(:min_id) { events[1].id }

    it 'prunes events up to the min id' do
      expect { service.execute }.to change { Geo::EventLog.count }.by(-2)
    end

    it 'prunes all associated events' do
      expect { service.execute }.to change { Geo::RepositoryUpdatedEvent.count }.by(-2)
    end
  end

  describe '#prune!' do
    it 'returns the number of rows pruned' do
      expect(service.send(:prune!, Geo::RepositoryUpdatedEvent, 50_000)).to eq(5)
    end
  end
end
