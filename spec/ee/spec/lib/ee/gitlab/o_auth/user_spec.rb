require 'spec_helper'

describe Gitlab::OAuth::User, lib: true do
  include LdapHelpers

  describe 'login through kerberos with linkable LDAP user' do
    let(:uid)        { 'foo' }
    let(:provider)   { 'kerberos' }
    let(:realm)      { 'ad.example.com' }
    let(:base_dn)    { 'ou=users,dc=ad,dc=example,dc=com' }
    let(:info_hash)  { { email: uid + '@' + realm, username: uid } }
    let(:auth_hash)  { OmniAuth::AuthHash.new(uid: uid, provider: provider, info: info_hash) }
    let(:oauth_user) { Gitlab::OAuth::User.new(auth_hash) }
    let(:real_email) { 'myname@example.com' }

    before do
      allow(::Gitlab::Kerberos::Authentication).to receive(:kerberos_default_realm).and_return(realm)
      allow(Gitlab.config.omniauth).to receive_messages(auto_link_ldap_user: true, allow_single_sign_on: ['kerberos'])
      stub_ldap_config(base: base_dn)

      ldap_entry = Net::LDAP::Entry.new("uid=#{uid}," + base_dn).tap do |entry|
        entry['uid'] = uid
        entry['email'] = real_email
      end

      stub_ldap_person_find_by_uid(uid, ldap_entry)

      oauth_user.save
    end

    it 'links the LDAP person to the GitLab user' do
      gl_user = oauth_user.gl_user

      identities = gl_user.identities.map do |identity|
        { provider: identity.provider, extern_uid: identity.extern_uid }
      end

      expect(identities).to contain_exactly(
        { provider: 'ldapmain', extern_uid: "uid=#{uid},#{base_dn}" },
        { provider: 'kerberos', extern_uid: uid + '@' + realm }
      )
 
      expect(gl_user.email).to eq(real_email)
    end
  end
end
