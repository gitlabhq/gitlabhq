# frozen_string_literal: true

RSpec.describe QA::Scenario::Test::Integration::ServicePingDisabled do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:service_ping_disabled] }
    end
  end
end
