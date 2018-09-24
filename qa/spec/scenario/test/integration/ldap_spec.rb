# frozen_string_literal: true

describe QA::Scenario::Test::Integration::LDAP do
  context '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:ldap] }
    end
  end
end
