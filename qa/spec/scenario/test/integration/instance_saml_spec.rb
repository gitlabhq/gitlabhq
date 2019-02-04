# frozen_string_literal: true

describe QA::Scenario::Test::Integration::InstanceSAML do
  context '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:instance_saml] }
    end
  end
end
