require 'rails_helper'

RSpec.describe Geo::MetricsUpdateWorker, :geo do
  include ::EE::GeoHelpers

  subject { described_class.new }

  describe '#perform' do
    let(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(secondary)
    end

    it 'executes MetricsUpdateService' do
      service = double(:service, execute: true)
      expect(Geo::MetricsUpdateService).to receive(:new).and_return(service)

      subject.perform
    end
  end
end
