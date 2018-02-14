require 'spec_helper'

describe Geo::SidekiqCronConfigWorker do
  describe '#perform' do
    it 'runs the cron manager' do
      manager = double('cron_manager')
      allow(Gitlab::Geo::CronManager).to receive(:new) { manager }

      expect(manager).to receive(:execute)

      described_class.new.perform
    end
  end
end
