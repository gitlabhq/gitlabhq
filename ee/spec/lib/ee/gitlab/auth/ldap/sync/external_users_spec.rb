require 'spec_helper'

describe EE::Gitlab::Auth::LDAP::Sync::ExternalUsers do
  include LdapHelpers

  describe '#update_permissions' do
    let(:adapter) { ldap_adapter }
    let(:sync_external) { described_class.new(proxy(adapter)) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:external_group1) { ldap_group_entry(user_dn(user1.username), cn: 'external_group1') }
    let(:external_group2) { ldap_group_entry(user_dn(user2.username), cn: 'external_group2') }

    before do
      stub_ldap_config(
        external_groups: %w(external_group1 external_group2),
        active_directory: false
      )
      stub_ldap_group_find_by_cn('external_group1', external_group1, adapter)
      stub_ldap_group_find_by_cn('external_group2', external_group2, adapter)
    end

    it 'adds users from both external LDAP groups as external users' do
      create(:identity, user: user1, extern_uid: user_dn(user1.username))
      create(:identity, user: user2, extern_uid: user_dn(user2.username))

      sync_external.update_permissions

      expect(user1.reload.external?).to be true
      expect(user2.reload.external?).to be true
    end

    it 'removes users that are not in the LDAP group' do
      user = create(:external_user)
      create(:identity, user: user, extern_uid: user_dn(user.username))

      expect { sync_external.update_permissions }
        .to change { user.reload.external? }.from(true).to(false)
    end

    it 'leaves external users that do not have the LDAP provider' do
      user = create(:external_user)

      expect { sync_external.update_permissions }
        .not_to change { user.reload.external? }
    end

    it 'leaves external users that have a different provider identity' do
      user = create(:external_user)
      create(:identity, user: user, provider: 'ldapsecondary', extern_uid: user_dn(user.username))

      expect { sync_external.update_permissions }
        .not_to change { user.reload.external? }
    end

    context 'when ldap connection fails' do
      before do
        unstub_ldap_group_find_by_cn
        raise_ldap_connection_error
      end

      it 'logs a debug message' do
        expect(Rails.logger)
          .to receive(:warn)
                .with("Error syncing external users for provider 'ldapmain'. LDAP connection Error")
                .at_least(:once)

        sync_external.update_permissions
      end
    end
  end
end
