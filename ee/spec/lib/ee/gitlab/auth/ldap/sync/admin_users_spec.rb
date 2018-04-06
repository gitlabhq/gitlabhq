require 'spec_helper'

describe EE::Gitlab::Auth::LDAP::Sync::AdminUsers do
  include LdapHelpers

  let(:adapter) { ldap_adapter }

  describe '#update_permissions' do
    let(:sync_admin) { described_class.new(proxy(adapter)) }

    let(:user) { create(:user) }

    let(:admin_group) do
      ldap_group_entry(user_dn(user.username), cn: 'admin_group')
    end

    before do
      stub_ldap_config(admin_group: 'admin_group', active_directory: false)
      stub_ldap_group_find_by_cn('admin_group', admin_group, adapter)
    end

    it 'adds user as admin' do
      create(:identity, user: user, extern_uid: user_dn(user.username))

      expect { sync_admin.update_permissions }
        .to change { user.reload.admin? }.from(false).to(true)
    end

    it 'removes users that are not in the LDAP group' do
      admin = create(:admin)
      create(:identity, user: admin, extern_uid: user_dn(admin.username))

      expect { sync_admin.update_permissions }
        .to change { admin.reload.admin? }.from(true).to(false)
    end

    it 'leaves admin users that do not have the LDAP provider' do
      admin = create(:admin)

      expect { sync_admin.update_permissions }
        .not_to change { admin.reload.admin? }
    end

    it 'leaves admin users that have a different provider identity' do
      admin = create(:admin)
      create(:identity,
             user: admin,
             provider: 'ldapsecondary',
             extern_uid: user_dn(admin.username))

      expect { sync_admin.update_permissions }
        .not_to change { admin.reload.admin? }
    end

    context 'when ldap connection fails' do
      before do
        unstub_ldap_group_find_by_cn
        raise_ldap_connection_error
      end

      it 'logs a debug message' do
        expect(Rails.logger)
          .to receive(:warn)
                .with("Error syncing admin users for provider 'ldapmain'. LDAP connection Error")
                .at_least(:once)

        sync_admin.update_permissions
      end
    end
  end
end
