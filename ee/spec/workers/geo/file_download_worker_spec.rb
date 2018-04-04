require 'spec_helper'

describe Geo::FileDownloadWorker, :geo do
  describe '#perform' do
    it 'instantiates and executes FileDownloadService' do
      service = double(:service)
      expect(service).to receive(:execute)
      expect(Geo::FileDownloadService).to receive(:new).with('job_artifact', 1).and_return(service)
      described_class.new.perform('job_artifact', 1)
    end
  end
end
