require 'spec_helper'

describe EE::Gitlab::Auth::LDAP::UserFilter do
  include LdapHelpers

  let(:auth_hash) do
    OmniAuth::AuthHash.new(uid: 'uid=john,ou=people,dc=example,dc=com', provider: 'ldapmain')
  end
  let!(:fake_proxy) { fake_ldap_sync_proxy(auth_hash.provider) }
  let(:fake_entry) { ldap_user_entry('user1') }

  before do
    stub_ldap_config(
      base: 'dc=example,dc=com',
      active_directory: false
    )

    allow(fake_proxy).to receive(:provider)
  end

  describe '#filter' do
    it 'returns dns from an LDAP search' do
      filter = '(ou=people)'

      allow(fake_proxy.adapter).to receive(:ldap_search).and_return([fake_entry])

      expect(described_class.filter(fake_proxy, filter)).to eq(['uid=user1,ou=users,dc=example,dc=com'])
    end

    it 'errors out with an invalid filter' do
      filter = ')('

      expect { described_class.filter(fake_proxy, filter) }.to raise_error(Net::LDAP::FilterSyntaxInvalidError, 'Invalid filter syntax.')
    end
  end
end
