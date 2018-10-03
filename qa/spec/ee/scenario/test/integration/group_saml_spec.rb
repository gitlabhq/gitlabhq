# frozen_string_literal: true

describe QA::EE::Scenario::Test::Integration::GroupSAML do
  context '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:group_saml] }
    end
  end
end
