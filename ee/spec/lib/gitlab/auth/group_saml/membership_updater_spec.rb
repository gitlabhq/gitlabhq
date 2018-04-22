require 'spec_helper'

describe Gitlab::Auth::GroupSaml::MembershipUpdater do
  let(:user) { create(:user) }
  let(:saml_provider) { create(:saml_provider) }
  let(:group) { saml_provider.group }

  it "adds the user to the group" do
    described_class.new(user, saml_provider).execute

    expect(group.users).to include(user)
  end

  it "doesn't duplicate group membership" do
    group.add_guest(user)

    described_class.new(user, saml_provider).execute

    expect(group.members.count).to eq 1
  end

  it "doesn't overwrite existing membership level" do
    group.add_master(user)

    described_class.new(user, saml_provider).execute

    expect(group.members.pluck(:access_level)).to eq([Gitlab::Access::MASTER])
  end
end
