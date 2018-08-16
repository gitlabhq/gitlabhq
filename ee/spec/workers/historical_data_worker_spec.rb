require 'spec_helper'

describe HistoricalDataWorker do
  subject { described_class.new }

  describe '#perform' do
    context 'with a trial license' do
      before do
        FactoryBot.create(:license, trial: true)
      end

      it 'does not track historical data' do
        expect(HistoricalData).not_to receive(:track!)

        subject.perform
      end
    end

    context 'with a non trial license' do
      before do
        FactoryBot.create(:license)
      end

      it 'tracks historical data' do
        expect(HistoricalData).to receive(:track!)

        subject.perform
      end
    end

    context 'when there is not a license key' do
      it 'does not track historical data' do
        License.destroy_all # rubocop: disable DestroyAll

        expect(HistoricalData).not_to receive(:track!)

        subject.perform
      end
    end
  end
end
