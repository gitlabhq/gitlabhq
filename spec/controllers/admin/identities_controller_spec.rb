# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::IdentitiesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #index' do
    context 'when the user has no identities' do
      it 'shows no identities' do
        get :index, params: { user_id: admin.username }

        expect(assigns(:user)).to eq(admin)
        expect(assigns(:identities)).to be_blank
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when the user has identities' do
      let(:ldap_user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'ldap-uid') }

      it 'shows identities' do
        get :index, params: { user_id: ldap_user.username }

        expect(assigns(:user)).to eq(ldap_user)
        expect(assigns(:identities)).to eq(ldap_user.identities)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'UPDATE identity' do
    let(:user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'uid=myuser,ou=people,dc=example,dc=com') }

    it 'repairs ldap blocks' do
      expect_next_instance_of(::Users::RepairLdapBlockedService) do |instance|
        expect(instance).to receive(:execute)
      end

      put :update, params: { user_id: user.username, id: user.ldap_identity.id, identity: { provider: 'twitter' } }
    end
  end

  describe 'DELETE identity' do
    let(:user) { create(:omniauth_user, provider: 'ldapmain', extern_uid: 'uid=myuser,ou=people,dc=example,dc=com') }

    it 'repairs ldap blocks' do
      expect_next_instance_of(::Users::RepairLdapBlockedService) do |instance|
        expect(instance).to receive(:execute)
      end

      delete :destroy, params: { user_id: user.username, id: user.ldap_identity.id }
    end
  end
end
