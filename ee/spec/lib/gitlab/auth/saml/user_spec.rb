require 'spec_helper'

describe Gitlab::Auth::Saml::User do
  include LdapHelpers
  include LoginHelpers

  let(:saml_user) { described_class.new(auth_hash) }
  let(:gl_user) { saml_user.gl_user }
  let(:uid) { 'my-uid' }
  let(:dn) { 'uid=user1,ou=people,dc=example' }
  let(:provider) { 'saml' }
  let(:raw_info_attr) { { 'groups' => %w(Developers Freelancers Designers) } }
  let(:auth_hash) { OmniAuth::AuthHash.new(uid: uid, provider: provider, info: info_hash, extra: { raw_info: OneLogin::RubySaml::Attributes.new(raw_info_attr) }) }
  let(:info_hash) do
    {
      name: 'John',
      email: 'john@mail.com'
    }
  end

  describe '#save' do
    def stub_omniauth_config(messages)
      allow(Gitlab.config.omniauth).to receive_messages(messages)
    end

    def stub_basic_saml_config
      allow(Gitlab::Auth::Saml::Config).to receive_messages({ options: { name: 'saml', args: {} } })
    end

    def stub_saml_required_group_config(groups)
      allow(Gitlab::Auth::Saml::Config).to receive_messages({ options: { name: 'saml', groups_attribute: 'groups', required_groups: groups, args: {} } })
    end

    def stub_saml_admin_group_config(groups)
      allow(Gitlab::Auth::Saml::Config).to receive_messages({ options: { name: 'saml', groups_attribute: 'groups', admin_groups: groups, args: {} } })
    end

    before do
      stub_basic_saml_config
    end

    describe 'account exists on server' do
      before do
        stub_omniauth_config({ allow_single_sign_on: ['saml'], auto_link_saml_user: true })
      end

      context 'admin groups' do
        context 'are defined' do
          it 'marks the user as admin' do
            stub_saml_admin_group_config(%w(Developers))
            saml_user.save

            expect(gl_user).to be_valid
            expect(gl_user.admin).to be_truthy
          end
        end

        before do
          stub_saml_admin_group_config(%w(Admins))
        end

        context 'are defined but the user does not belong there' do
          it 'does not mark the user as admin' do
            saml_user.save

            expect(gl_user).to be_valid
            expect(gl_user.admin).to be_falsey
          end
        end

        context 'user was admin, now should not be' do
          it 'makes user non admin' do
            create(:user, email: 'john@mail.com', username: 'john').update_attribute('admin', true)
            saml_user.save

            expect(gl_user).to be_valid
            expect(gl_user.admin).to be_falsey
          end
        end
      end
    end

    describe 'no account exists on server' do
      context 'required groups' do
        context 'not defined' do
          it 'lets anyone in' do
            saml_user.save

            expect(gl_user).to be_valid
          end
        end

        context 'are defined' do
          before do
            stub_omniauth_config(block_auto_created_users: false)
          end

          it 'lets members in' do
            stub_saml_required_group_config(%w(Developers))
            saml_user.save

            expect(gl_user).to be_valid
          end

          it 'unblocks already blocked members' do
            stub_saml_required_group_config(%w(Developers))
            saml_user.save.ldap_block

            expect(saml_user.find_user).to be_active
          end

          it 'does not allow non-members' do
            stub_saml_required_group_config(%w(ArchitectureAstronauts))

            expect { saml_user.save }.to raise_error Gitlab::Auth::OAuth::User::SignupDisabledError
          end

          it 'blocks non-members' do
            orig_groups = auth_hash.extra.raw_info["groups"]
            auth_hash.extra.raw_info.add("groups", "ArchitectureAstronauts")
            stub_saml_required_group_config(%w(ArchitectureAstronauts))
            saml_user.save
            auth_hash.extra.raw_info.set("groups", orig_groups)

            expect(saml_user.find_user).to be_ldap_blocked
          end
        end
      end

      context 'admin groups' do
        context 'are defined' do
          it 'marks the user as admin' do
            stub_saml_admin_group_config(%w(Developers))
            saml_user.save

            expect(gl_user).to be_valid
            expect(gl_user.admin).to be_truthy
          end
        end

        context 'are defined but the user does not belong there' do
          it 'does not mark the user as admin' do
            stub_saml_admin_group_config(%w(Admins))
            saml_user.save

            expect(gl_user).to be_valid
            expect(gl_user.admin).to be_falsey
          end
        end
      end
    end
  end
end
