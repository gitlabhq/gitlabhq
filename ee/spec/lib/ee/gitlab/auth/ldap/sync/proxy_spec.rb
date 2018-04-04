require 'spec_helper'
require 'net/ldap/dn'

describe EE::Gitlab::Auth::LDAP::Sync::Proxy do
  include LdapHelpers

  let(:adapter) { ldap_adapter }
  let(:sync_proxy) { described_class.new('ldapmain', adapter) }

  before do
    stub_ldap_config(active_directory: false)
  end

  describe '#dns_for_group_cn' do
    it 'returns an empty array when LDAP group cannot be found' do
      stub_ldap_group_find_by_cn('ldap_group1', nil, adapter)

      expect(sync_proxy.dns_for_group_cn('ldap_group1')).to eq([])
    end

    it 'returns an empty array when LDAP group has no members' do
      ldap_group = ldap_group_entry(nil)
      stub_ldap_group_find_by_cn('ldap_group1', ldap_group, adapter)

      expect(sync_proxy.dns_for_group_cn('ldap_group1')).to eq([])
    end

    context 'with a valid LDAP group that contains ASCII-8BIT-encoded Unicode data' do
      let(:username) { 'Méräy'.force_encoding('ASCII-8BIT') }
      let(:dns) { [user_dn(username)] }

      it 'return members DNs' do
        ldap_group = ldap_group_entry(dns)
        stub_ldap_group_find_by_cn('ldap_group1', ldap_group, adapter)

        expect(sync_proxy.dns_for_group_cn('ldap_group1').first).to include("uid=méräy")
      end
    end

    context 'with a valid LDAP group that contains members' do
      # Create some random usernames and DNs
      let(:usernames) { (1..4).map { generate(:username) } }
      let(:dns) { usernames.map { |u| user_dn(u) } }

      it 'returns member DNs' do
        ldap_group = ldap_group_entry(dns)
        stub_ldap_group_find_by_cn('ldap_group1', ldap_group, adapter)

        expect(sync_proxy.dns_for_group_cn('ldap_group1')).to match_array(dns)
      end

      it 'returns cached results after the first lookup' do
        ldap_group = ldap_group_entry(dns)
        stub_ldap_group_find_by_cn('ldap_group1', ldap_group, adapter)
        # Do the first lookup to build the cache
        sync_proxy.dns_for_group_cn('ldap_group1')

        expect(sync_proxy).not_to receive(:ldap_group_member_dns)
        expect(EE::Gitlab::Auth::LDAP::Group).not_to receive(:find_by_cn)

        sync_proxy.dns_for_group_cn('ldap_group1')
      end

      # posixGroup - Apple Open Directory
      it 'returns member DNs for posixGroup' do
        ldap_group = ldap_group_entry(
          usernames,
          objectclass: 'posixGroup',
          member_attr: 'memberUid'
        )
        stub_ldap_group_find_by_cn('ldap_group1', ldap_group, adapter)
        usernames.each do |username|
          stub_ldap_person_find_by_uid(username, ldap_user_entry(username))
        end

        expect(sync_proxy.dns_for_group_cn('ldap_group1')).to match_array(dns)
      end

      it 'returns member DNs when member value is in uid=<user> format' do
        ldap_group = ldap_group_entry(usernames.map { |u| "uid=#{u}" })
        stub_ldap_group_find_by_cn('ldap_group1', ldap_group, adapter)
        usernames.each do |username|
          stub_ldap_person_find_by_uid(username, ldap_user_entry(username))
        end

        expect(sync_proxy.dns_for_group_cn('ldap_group1')).to match_array(dns)
      end

      it 'returns valid DNs while gracefully skipping malformed DNs' do
        mixed_dns = dns.dup << 'invalid_dn'
        ldap_group = ldap_group_entry(mixed_dns)
        stub_ldap_group_find_by_cn('ldap_group1', ldap_group, adapter)

        expect(sync_proxy.dns_for_group_cn('ldap_group1')).to match_array(dns)
      end

      it 'returns valid DNs while gracefully handling empty entries' do
        mixed_dns = dns.dup << ''
        ldap_group = ldap_group_entry(mixed_dns)
        stub_ldap_group_find_by_cn('ldap_group1', ldap_group, adapter)

        expect(sync_proxy.dns_for_group_cn('ldap_group1')).to match_array(dns)
      end
    end

    context 'when there is a connection problem' do
      before do
        raise_ldap_connection_error
      end

      it 'raises exception' do
        expect { sync_proxy.dns_for_group_cn('ldap_group1') }.to raise_error(::Gitlab::Auth::LDAP::LDAPConnectionError)
      end
    end
  end

  describe '#dn_for_uid' do
    it 'returns nil when no user is found' do
      stub_ldap_person_find_by_uid('john_doe', nil)

      expect(sync_proxy.dn_for_uid('john_doe')).to be_nil
    end

    context 'when secondary_extern_uid is not stored in the database' do
      before do
        ldap_user_entry = ldap_user_entry('jane_doe')
        stub_ldap_person_find_by_uid('jane_doe', ldap_user_entry)
      end

      it 'returns the user DN' do
        expect(sync_proxy.dn_for_uid('jane_doe'))
          .to eq('uid=jane_doe,ou=users,dc=example,dc=com')
      end

      it 'retrieves the user from LDAP' do
        expect(::Gitlab::Auth::LDAP::Person).to receive(:find_by_uid)

        sync_proxy.dn_for_uid('jane_doe')
      end

      it 'returns cached results after the first lookup' do
        sync_proxy.dn_for_uid('jane_doe')

        expect(sync_proxy).not_to receive(:member_uid_to_dn)
        expect(Identity).not_to receive(:find_by)
        expect(::Gitlab::Auth::LDAP::Person).not_to receive(:find_by_uid)

        sync_proxy.dn_for_uid('jane_doe')
      end

      it 'saves the secondary_extern_uid' do
        user = create(:user)
        create(:identity, user: user, extern_uid: user_dn(user.username))
        ldap_user_entry = ldap_user_entry(user.username)
        stub_ldap_person_find_by_uid(user.username, ldap_user_entry)

        expect { sync_proxy.dn_for_uid(user.username) }
          .to change {
            user.identities.first.secondary_extern_uid
          }.from(nil).to(user.username)
      end

      it 'is graceful when no user with LDAP identity is found' do
        # Create a user with no LDAP identity
        user = create(:user)
        ldap_user_entry = ldap_user_entry(user.username)
        stub_ldap_person_find_by_uid(user.username, ldap_user_entry)

        expect { sync_proxy.dn_for_uid(user.username) }.not_to raise_error
      end
    end

    context 'when secondary_extern_uid is stored in the database' do
      let(:user) { create(:user) }

      before do
        create(
          :identity,
          user: user,
          extern_uid: user_dn(user.username),
          secondary_extern_uid: user.username
        )
      end

      after do
        sync_proxy.dn_for_uid(user.username)
      end

      it 'does not query LDAP' do
        expect(::Gitlab::Auth::LDAP::Person).not_to receive(:find_by_uid)
      end

      it 'retrieves the DN from the identity' do
        expect(Identity)
          .to receive(:with_secondary_extern_uid)
                .with(sync_proxy.provider, user.username)
                .once.and_call_original
      end
    end

    context 'when there is a connection problem' do
      before do
        raise_ldap_connection_error
      end

      it 'raises exception' do
        expect { sync_proxy.dns_for_group_cn('ldap_group1') }.to raise_error(::Gitlab::Auth::LDAP::LDAPConnectionError)
      end
    end
  end
end
