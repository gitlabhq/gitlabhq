# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::IdentitiesHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:identity) { create(:identity, provider: 'ldapmain', extern_uid: 'ldap-uid') }

  describe '#label_for_identity_provider' do
    it 'shows label for identity provider' do
      expect(helper.label_for_identity_provider(identity)).to eq 'ldap (ldapmain)'
    end
  end

  describe '#provider_id_cell_testid' do
    it 'shows blank provider id for data-testid' do
      expect(helper.provider_id_cell_testid(identity)).to eq 'provider_id_blank'
    end
  end

  describe '#provider_id' do
    it 'shows no provider id' do
      expect(helper.provider_id(identity)).to eq '-'
    end
  end

  describe '#saml_group_cell_testid' do
    it 'shows blank SAML group for data-testid' do
      expect(helper.saml_group_cell_testid(identity)).to eq 'saml_group_blank'
    end
  end

  describe '#saml_group_link' do
    it 'shows no link to SAML group' do
      expect(helper.saml_group_link(identity)).to eq '-'
    end
  end
end
