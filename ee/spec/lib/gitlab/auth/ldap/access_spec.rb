require 'spec_helper'

describe Gitlab::Auth::LDAP::Access do
  include LdapHelpers

  let(:user) { create(:omniauth_user) }
  let(:provider) { user.ldap_identity.provider }

  subject(:access) { described_class.new(user) }

  describe '#allowed?' do
    context 'LDAP user' do
      it 'finds a user by dn first' do
        expect(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(:ldap_user)
        expect(Gitlab::Auth::LDAP::Person).not_to receive(:find_by_email)

        access.allowed?
      end

      it 'finds a user by email if not found by dn' do
        expect(Gitlab::Auth::LDAP::Person).to receive(:find_by_dn).and_return(nil)
        expect(Gitlab::Auth::LDAP::Person).to receive(:find_by_email)

        access.allowed?
      end

      it 'returns false if user cannot be found' do
        stub_ldap_person_find_by_dn(nil)
        stub_ldap_person_find_by_email(user.email, nil)

        expect(access.allowed?).to be_falsey
      end
    end
  end

  describe '#update_user' do
    let(:entry) { Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com") }

    context 'email address' do
      before do
        stub_ldap_person_find_by_dn(entry, provider)
      end

      it 'does not update email if email attribute is not set' do
        expect { access.update_user }.not_to change(user, :email)
      end

      it 'does not update the email if the user has the same email in GitLab and in LDAP' do
        entry['mail'] = [user.email]

        expect { access.update_user }.not_to change(user, :email)
      end

      it 'does not update the email if the user has the same email GitLab and in LDAP, but with upper case in LDAP' do
        entry['mail'] = [user.email.upcase]

        expect { access.update_user }.not_to change(user, :email)
      end

      it 'does not update the email when in a read-only GitLab instance' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)

        entry['mail'] = ['new_email@example.com']

        expect { access.update_user }.not_to change(user, :email)
      end

      it 'updates the email if the user email is different' do
        entry['mail'] = ['new_email@example.com']

        expect { access.update_user }.to change(user, :email)
      end
    end

    context 'group memberships' do
      context 'when there is `memberof` param' do
        before do
          entry['memberof'] = [
            'CN=Group1,CN=Users,DC=The dc,DC=com',
            'CN=Group2,CN=Builtin,DC=The dc,DC=com'
          ]

          stub_ldap_person_find_by_dn(entry, provider)
        end

        it 'triggers a sync for all groups found in `memberof`' do
          group_link_1 = create(:ldap_group_link, cn: 'Group1', provider: provider)
          group_link_2 = create(:ldap_group_link, cn: 'Group2', provider: provider)
          group_ids = [group_link_1, group_link_2].map(&:group_id)

          expect(LdapGroupSyncWorker).to receive(:perform_async)
            .with(a_collection_containing_exactly(*group_ids), provider)

          access.update_user
        end

        it "doesn't trigger a sync when in a read-only GitLab instance" do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          create(:ldap_group_link, cn: 'Group1', provider: provider)
          create(:ldap_group_link, cn: 'Group2', provider: provider)

          expect(LdapGroupSyncWorker).not_to receive(:perform_async)

          access.update_user
        end

        it "doesn't trigger a sync when there are no links for the provider" do
          _another_provider = create(:ldap_group_link,
                                     cn: 'Group1',
                                     provider: 'not-this-ldap')

          expect(LdapGroupSyncWorker).not_to receive(:perform_async)

          access.update_user
        end
      end

      it "doesn't continue when there is no `memberOf` param" do
        stub_ldap_person_find_by_dn(entry, provider)

        expect(LdapGroupLink).not_to receive(:where)
        expect(LdapGroupSyncWorker).not_to receive(:perform_async)

        access.update_user
      end
    end

    context 'SSH keys' do
      let(:ssh_key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrSQHff6a1rMqBdHFt+FwIbytMZ+hJKN3KLkTtOWtSvNIriGhnTdn4rs+tjD/w+z+revytyWnMDM9dS7J8vQi006B16+hc9Xf82crqRoPRDnBytgAFFQY1G/55ql2zdfsC5yvpDOFzuwIJq5dNGsojS82t6HNmmKPq130fzsenFnj5v1pl3OJvk513oduUyKiZBGTroWTn7H/eOPtu7s9MD7pAdEjqYKFLeaKmyidiLmLqQlCRj3Tl2U9oyFg4PYNc0bL5FZJ/Z6t0Ds3i/a2RanQiKxrvgu3GSnUKMx7WIX373baL4jeM7cprRGiOY/1NcS+1cAjfJ8oaxQF/1dYj' }
      let(:ssh_key_attribute_name) { 'altSecurityIdentities' }
      let(:entry) { Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: SSHKey:#{ssh_key}\n#{ssh_key_attribute_name}: KerberosKey:bogus") }

      before do
        stub_ldap_config(sync_ssh_keys: ssh_key_attribute_name, sync_ssh_keys?: true)
      end

      it 'adds a SSH key if it is in LDAP but not in gitlab' do
        stub_ldap_person_find_by_dn(entry, provider)

        expect { access.update_user }.to change(user.keys, :count).from(0).to(1)
      end

      it 'adds a SSH key and give it a proper name' do
        stub_ldap_person_find_by_dn(entry, provider)

        access.update_user

        expect(user.keys.last.title).to match(/LDAP/)
        expect(user.keys.last.title).to match(/#{ssh_key_attribute_name}/)
      end

      it 'does not add a SSH key if it is invalid' do
        entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}: I am not a valid key")
        stub_ldap_person_find_by_dn(entry, provider)

        expect { access.update_user }.not_to change(user.keys, :count)
      end

      it 'does not add a SSH key when in a read-only GitLab instance' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        stub_ldap_person_find_by_dn(entry, provider)

        expect { access.update_user }.not_to change(user.keys, :count)
      end

      context 'user has at least one LDAPKey' do
        before do
          user.keys.ldap.create key: ssh_key, title: 'to be removed'
        end

        it 'removes a SSH key if it is no longer in LDAP' do
          entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com\n#{ssh_key_attribute_name}:\n")
          stub_ldap_person_find_by_dn(entry, provider)

          expect { access.update_user }.to change(user.keys, :count).from(1).to(0)
        end

        it 'removes a SSH key if the ldap attribute was removed' do
          entry = Net::LDAP::Entry.from_single_ldif_string("dn: cn=foo, dc=bar, dc=com")
          stub_ldap_person_find_by_dn(entry, provider)

          expect { access.update_user }.to change(user.keys, :count).from(1).to(0)
        end
      end
    end

    context 'kerberos identity' do
      before do
        stub_ldap_config(active_directory: true)
        stub_kerberos_setting(enabled: true)
        stub_ldap_person_find_by_dn(entry, provider)
      end

      it 'adds a Kerberos identity if it is in Active Directory but not in GitLab' do
        allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: 'mylogin@FOO.COM')

        expect { access.update_user }.to change(user.identities.where(provider: :kerberos), :count).from(0).to(1)
        expect(user.identities.where(provider: 'kerberos').last.extern_uid).to eq('mylogin@FOO.COM')
      end

      it 'updates existing Kerberos identity in GitLab if Active Directory has a different one' do
        allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: 'otherlogin@BAR.COM')
        user.identities.build(provider: 'kerberos', extern_uid: 'mylogin@FOO.COM').save

        expect { access.update_user }.not_to change(user.identities.where(provider: 'kerberos'), :count)
        expect(user.identities.where(provider: 'kerberos').last.extern_uid).to eq('otherlogin@BAR.COM')
      end

      it 'does not remove Kerberos identities from GitLab if they are none in the LDAP provider' do
        allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: nil)
        user.identities.build(provider: 'kerberos', extern_uid: 'otherlogin@BAR.COM').save

        expect { access.update_user }.not_to change(user.identities.where(provider: 'kerberos'), :count)
        expect(user.identities.where(provider: 'kerberos').last.extern_uid).to eq('otherlogin@BAR.COM')
      end

      it 'does not modify identities in GitLab if they are no kerberos principal in the LDAP provider' do
        allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: nil)

        expect { access.update_user }.not_to change(user.identities, :count)
      end

      it 'does not add a Kerberos identity when in a read-only GitLab instance' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        allow_any_instance_of(EE::Gitlab::Auth::LDAP::Person).to receive_messages(kerberos_principal: 'mylogin@FOO.COM')

        expect { access.update_user }.not_to change(user.identities.where(provider: :kerberos), :count)
      end
    end

    context 'LDAP entity' do
      context 'whent external UID changed in the entry' do
        before do
          stub_ldap_person_find_by_dn(ldap_user_entry('another uid'), provider)
        end

        it 'updates the external UID' do
          access.update_user

          expect(user.ldap_identity.reload.extern_uid)
            .to eq('uid=another uid,ou=users,dc=example,dc=com')
        end

        it 'does not update the external UID when in a read-only GitLab instance' do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)

          access.update_user

          expect(user.ldap_identity.reload.extern_uid).to eq('123456')
        end
      end
    end
  end
end
