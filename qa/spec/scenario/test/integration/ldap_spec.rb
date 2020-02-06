# frozen_string_literal: true

describe QA::Scenario::Test::Integration::LDAPNoTLS do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:ldap_no_tls] }
    end
  end
end

describe QA::Scenario::Test::Integration::LDAPNoServer do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:ldap_no_server] }
    end
  end
end

describe QA::Scenario::Test::Integration::LDAPTLS do
  describe '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:ldap_tls] }
    end
  end
end
