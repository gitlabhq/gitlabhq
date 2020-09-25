# frozen_string_literal: true

RSpec.describe QA::Scenario::Test::Integration::Kubernetes do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:kubernetes] }
    end
  end
end
