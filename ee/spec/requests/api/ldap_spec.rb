require 'spec_helper'

describe API::Ldap do
  include ApiHelpers
  include LdapHelpers

  set(:user) { create(:user) }
  set(:admin) { create(:admin) }
  let(:adapter) { ldap_adapter }

  before do
    groups = [
      OpenStruct.new(cn: 'developers'),
      OpenStruct.new(cn: 'students')
    ]

    allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)
    allow(Gitlab::Auth::LDAP::Adapter).to receive(:new).and_return(adapter)
    allow(adapter).to receive_messages(groups: groups)
    stub_application_setting(allow_group_owners_to_manage_ldap: false)
  end

  describe "GET /ldap/groups" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/ldap/groups")
        expect(response.status).to eq 401
      end
    end

    context "when authenticated as user" do
      it "returns authentication error" do
        get api("/ldap/groups", user)
        expect(response.status).to eq 403
      end
    end

    context 'when group owners are allowed to manage LDAP' do
      before do
        stub_application_setting(allow_group_owners_to_manage_ldap: true)
      end

      it "returns an array of ldap groups" do
        get api("/ldap/groups", user)
        expect(response.status).to eq 200
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end

    context "when authenticated as admin" do
      it "returns an array of ldap groups" do
        get api("/ldap/groups", admin)
        expect(response.status).to eq 200
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end
  end

  describe "GET /ldap/ldapmain/groups" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/ldap/ldapmain/groups")
        expect(response.status).to eq 401
      end
    end

    context "when authenticated as user" do
      it "returns authentication error" do
        get api("/ldap/ldapmain/groups", user)
        expect(response.status).to eq 403
      end
    end

    context 'when group owners are allowed to manage LDAP' do
      before do
        stub_application_setting(allow_group_owners_to_manage_ldap: true)
      end

      it "returns an array of ldap groups" do
        get api("/ldap/ldapmain/groups", admin)
        expect(response.status).to eq 200
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end

    context "when authenticated as admin" do
      it "returns an array of ldap groups" do
        get api("/ldap/ldapmain/groups", admin)
        expect(response.status).to eq 200
        expect(json_response).to be_an Array
        expect(json_response.length).to eq 2
        expect(json_response.first['cn']).to eq 'developers'
      end
    end
  end
end
