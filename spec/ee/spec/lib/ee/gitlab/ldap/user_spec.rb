require 'spec_helper'

describe Gitlab::LDAP::User do
  include LdapHelpers

  let(:ldap_user) { described_class.new(auth_hash) }
  let(:gl_user) { ldap_user.gl_user }
  let(:info) do
    {
      name: 'John',
      email: 'john@example.com',
      nickname: 'john'
    }
  end
  let(:auth_hash) do
    OmniAuth::AuthHash.new(uid: 'uid=john,ou=people,dc=example,dc=com', provider: 'ldapmain', info: info)
  end
  let(:group_cn) { 'foo' }
  let(:group_member_dns) { [auth_hash.uid] }
  let(:external_groups) { [] }
  let!(:fake_proxy) { fake_ldap_sync_proxy(auth_hash.provider) }

  before do
    allow(fake_proxy).to receive(:dns_for_group_cn).with(group_cn).and_return(group_member_dns)
    stub_ldap_config(external_groups: external_groups)
  end

  it 'includes the EE module' do
    expect(described_class).to include_module(EE::Gitlab::LDAP::User)
  end

  describe '#initialize' do
    context 'when the user is in an external group' do
      let(:external_groups) { [group_cn] }

      it "sets the user's external flag to true" do
        expect(gl_user.external).to be_truthy
      end
    end

    context 'when the user is not in an external group' do
      it "sets the user's external flag to false" do
        expect(gl_user.external).to be_falsey
      end
    end
  end

  describe '#set_external_with_external_groups' do
    context 'when the LDAP user is in an external group' do
      let(:external_groups) { [group_cn] }

      before do
        gl_user.update!(external: false)
      end

      it 'sets the GitLab user external flag to true' do
        expect do
          ldap_user.set_external_with_external_groups(fake_proxy)
        end.to change { gl_user.external }.from(false).to(true)
      end
    end

    context 'when the LDAP user is not in an external group' do
      before do
        gl_user.update!(external: true)
      end

      it 'sets the GitLab user external flag to true' do
        expect do
          ldap_user.set_external_with_external_groups(fake_proxy)
        end.to change { gl_user.external }.from(true).to(false)
      end
    end
  end

  describe '#in_any_external_group?' do
    subject { ldap_user.in_any_external_group?(fake_proxy) }

    context 'when there is an external group' do
      let(:external_groups) { [group_cn] }

      context 'when the user is in an external group' do
        it 'returns true' do
          expect(subject).to be_truthy
        end
      end

      context 'when the user is not in an external group' do
        let(:group_member_dns) { ['uid=someone_else,ou=people,dc=example,dc=com'] }

        it 'returns false' do
          expect(subject).to be_falsey
        end
      end
    end

    context 'when are no external groups' do
      it 'returns false' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#in_group?' do
    subject { ldap_user.in_group?(fake_proxy, group_cn) }

    context 'when the LDAP user is in the group' do
      it 'returns true' do
        expect(subject).to be_truthy
      end
    end

    context 'when the LDAP user is not in the group' do
      let(:group_member_dns) { ['uid=someone_else,ou=people,dc=example,dc=com'] }

      it 'returns false' do
        expect(subject).to be_falsey
      end
    end
  end
end
