require 'spec_helper'

describe LdapGroupLink do
  let(:klass) { described_class }
  let(:ldap_group_link) { build :ldap_group_link }

  describe 'validation' do
    describe 'cn' do
      it 'validates uniqueness based on group_id and provider' do
        create(:ldap_group_link, cn: 'group1', group_id: 1, provider: 'ldapmain')

        group_link = build(:ldap_group_link,
          cn: 'group1', group_id: 1, provider: 'ldapmain')
        expect(group_link).not_to be_valid

        group_link.group_id = 2
        expect(group_link).to be_valid

        group_link.group_id = 1
        group_link.provider = 'ldapalt'
        expect(group_link).to be_valid
      end

      it 'is invalid when a filter is also present' do
        link = build(:ldap_group_link, filter: '(a=b)', group_id: 1, provider: 'ldapmain', cn: 'group1')

        expect(link).not_to be_valid
      end
    end

    describe 'filter' do
      it 'validates uniqueness based on group_id and provider' do
        create(:ldap_group_link, filter: '(a=b)', group_id: 1, provider: 'ldapmain', cn: nil)

        group_link = build(:ldap_group_link,
                           filter: '(a=b)', group_id: 1, provider: 'ldapmain', cn: nil)
        expect(group_link).not_to be_valid

        group_link.group_id = 2
        expect(group_link).to be_valid

        group_link.group_id = 1
        group_link.provider = 'ldapalt'
        expect(group_link).to be_valid
      end

      it 'validates the LDAP filter' do
        link = build(:ldap_group_link, filter: 'invalid', group_id: 1, provider: 'ldapmain', cn: nil)

        expect(link).not_to be_valid
      end
    end

    describe 'provider' do
      it 'shows the set value' do
        ldap_group_link.provider = '1235'
        expect( ldap_group_link.provider ).to eql '1235'
      end

      it 'defaults to the first ldap server if empty' do
        expect( klass.new.provider ).to eql Gitlab::Auth::LDAP::Config.providers.first
      end
    end
  end
end
