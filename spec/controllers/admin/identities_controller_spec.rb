require 'spec_helper'

describe Admin::IdentitiesController do
  let(:admin) { create(:admin) }
  before { sign_in(admin) }

  describe 'UPDATE identity' do
    let(:user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'uid=myuser,ou=people,dc=example,dc=com') }

    it 'repairs ldap blocks' do
      expect_any_instance_of(RepairLdapBlockedUserService).to receive(:execute)

      put :update, user_id: user.username, id: user.ldap_identity.id, identity: { provider: 'twitter' }
    end
  end

  describe 'DELETE identity' do
    let(:user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'uid=myuser,ou=people,dc=example,dc=com') }

    it 'repairs ldap blocks' do
      expect_any_instance_of(RepairLdapBlockedUserService).to receive(:execute)

      delete :destroy, user_id: user.username, id: user.ldap_identity.id
    end
  end
end
