# frozen_string_literal: true

describe QA::Scenario::Test::Integration::OAuth do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:oauth] }
    end
  end
end
