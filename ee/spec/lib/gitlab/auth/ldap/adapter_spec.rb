require 'spec_helper'

describe Gitlab::Auth::LDAP::Adapter do
  include LdapHelpers

  let(:adapter) { ldap_adapter('ldapmain') }

  it 'includes the EE module' do
    expect(described_class).to include_module(EE::Gitlab::Auth::LDAP::Adapter)
  end

  describe '#groups' do
    before do
      stub_ldap_config(
        group_base: 'ou=groups,dc=example,dc=com',
        active_directory: false
      )
    end

    it 'searches with the proper options' do
      # Requires this expectation style to match the filter
      expect(adapter).to receive(:ldap_search) do |arg|
        expect(arg[:filter].to_s).to eq('(cn=*)')
        expect(arg[:base]).to eq('ou=groups,dc=example,dc=com')
        expect(arg[:attributes]).to match(%w(dn cn memberuid member submember uniquemember memberof))
      end.and_return({})

      adapter.groups
    end

    it 'returns a group object if search returns a result' do
      entry = ldap_group_entry(%w(uid=john uid=mary), cn: 'group1')
      allow(adapter).to receive(:ldap_search).and_return([entry])

      results = adapter.groups('group1')

      expect(results.first).to be_a(EE::Gitlab::Auth::LDAP::Group)
      expect(results.first.cn).to eq('group1')
      expect(results.first.member_dns).to match_array(%w(uid=john uid=mary))
    end
  end
end
