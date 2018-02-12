require 'spec_helper'

describe API::V3::LdapGroupLinks, api: true  do
  include ApiHelpers

  let(:owner) { create(:user) }
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  let!(:group_with_ldap_links) do
    group = create(:group)
    group.ldap_group_links.create cn: 'ldap-group1', group_access: Gitlab::Access::MASTER, provider: 'ldap1'
    group.ldap_group_links.create cn: 'ldap-group2', group_access: Gitlab::Access::MASTER, provider: 'ldap2'
    group
  end

  before do
    group_with_ldap_links.add_owner owner
    group_with_ldap_links.add_user user, Gitlab::Access::DEVELOPER
  end
  describe 'DELETE /groups/:id/ldap_group_links/:cn' do
    context "when unauthenticated" do
      it "returns authentication error" do
        delete v3_api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1")
        expect(response.status).to eq 401
      end
    end

    context "when a less priviledged user" do
      it "does not remove the LDAP group link" do
        expect do
          delete v3_api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1", user)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(403)
      end
    end

    context "when owner of the group" do
      it "removes ldap group link" do
        expect do
          delete v3_api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1", owner)
        end.to change { group_with_ldap_links.ldap_group_links.count }.by(-1)

        expect(response.status).to eq(200)
      end

      it "returns 404 if LDAP group cn not used for a LDAP group link" do
        expect do
          delete v3_api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1356", owner)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(404)
      end
    end
  end

  describe 'DELETE /groups/:id/ldap_group_links/:provider/:cn' do
    context "when unauthenticated" do
      it "returns authentication error" do
        delete v3_api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2")
        expect(response.status).to eq 401
      end
    end

    context "when a less priviledged user" do
      it "does not remove the LDAP group link" do
        expect do
          delete v3_api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2", user)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(403)
      end
    end

    context "when owner of the group" do
      it "returns 404 if LDAP group cn not used for a LDAP group link for the specified provider" do
        expect do
          delete v3_api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap1/ldap-group2", owner)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response.status).to eq(404)
      end

      it "removes ldap group link" do
        expect do
          delete v3_api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2", owner)
        end.to change { group_with_ldap_links.ldap_group_links.count }.by(-1)

        expect(response.status).to eq(200)
      end
    end
  end
end
