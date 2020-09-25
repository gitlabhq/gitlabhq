# frozen_string_literal: true

RSpec.describe QA::Scenario::Test::Integration::InstanceSAML do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:instance_saml] }
    end
  end
end
