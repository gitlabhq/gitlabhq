# frozen_string_literal: true

describe QA::Scenario::Test::Integration::LDAPNoTLS do
  context '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:ldap_no_tls] }
    end
  end
end

describe QA::Scenario::Test::Integration::LDAPTLS do
  context '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:ldap_tls] }
    end
  end
end
