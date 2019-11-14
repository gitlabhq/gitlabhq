# frozen_string_literal: true

require 'spec_helper'

describe Admin::IdentitiesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'UPDATE identity' do
    let(:user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'uid=myuser,ou=people,dc=example,dc=com') }

    it 'repairs ldap blocks' do
      expect_next_instance_of(RepairLdapBlockedUserService) do |instance|
        expect(instance).to receive(:execute)
      end

      put :update, params: { user_id: user.username, id: user.ldap_identity.id, identity: { provider: 'twitter' } }
    end
  end

  describe 'DELETE identity' do
    let(:user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'uid=myuser,ou=people,dc=example,dc=com') }

    it 'repairs ldap blocks' do
      expect_next_instance_of(RepairLdapBlockedUserService) do |instance|
        expect(instance).to receive(:execute)
      end

      delete :destroy, params: { user_id: user.username, id: user.ldap_identity.id }
    end
  end
end
