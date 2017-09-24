require 'spec_helper'

describe EE::Gitlab::LDAP::UserFilter do
  include LdapHelpers

  let(:auth_hash) do
    OmniAuth::AuthHash.new(uid: 'uid=john,ou=people,dc=example,dc=com', provider: 'ldapmain')
  end
  let!(:fake_proxy) { fake_ldap_sync_proxy(auth_hash.provider) }

  before do
    stub_ldap_config(
        base: 'dc=example,dc=com',
        active_directory: false
    )
  end

  describe '#filter' do
    it 'returns dns from an LDAP search' do
      filter = '(ou=people)'

      entry = ldap_group_entry(%w(john mary))
      allow(fake_proxy.adapter).to receive(:ldap_search).and_return([entry])

      expect(described_class.filter(fake_proxy, filter)).to eq('')
    end
  end
end
