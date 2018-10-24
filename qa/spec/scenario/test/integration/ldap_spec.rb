# frozen_string_literal: true

describe QA::Scenario::Test::Integration::LDAPNoSSL do
  context '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:ldap_no_ssl] }
    end
  end
end

describe QA::Scenario::Test::Integration::LDAPSSL do
  context '#perform' do
    it_behaves_like 'a QA scenario class' do
      let(:tags) { [:ldap_ssl] }
    end
  end
end
