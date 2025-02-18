# frozen_string_literal: true

RSpec.describe QA::Scenario::Test::Instance::Airgapped do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { %w[~github ~external_api_calls ~skip_live_env ~orchestrated] }
    end
  end
end
