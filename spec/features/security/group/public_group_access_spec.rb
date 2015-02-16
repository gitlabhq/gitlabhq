require 'spec_helper'

describe "Group with public project access", feature: true  do
  describe "Group" do
    let(:group) { create(:group) }

    let(:owner)   { create(:owner) }
    let(:master)   { create(:user) }
    let(:reporter) { create(:user) }
    let(:guest)    { create(:user) }
    let(:nonmember)  { create(:user) }

    before do
      group.add_user(owner, Gitlab::Access::OWNER)
      group.add_user(master, Gitlab::Access::MASTER)
      group.add_user(reporter, Gitlab::Access::REPORTER)
      group.add_user(guest, Gitlab::Access::GUEST)

      create(:project, :public, group: group)
    end

    describe "GET /groups/:path" do
      subject { group_path(group) }

      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_allowed_for master }
      it { is_expected.to be_allowed_for reporter }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for guest }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    describe "GET /groups/:path/issues" do
      subject { issues_group_path(group) }

      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_allowed_for master }
      it { is_expected.to be_allowed_for reporter }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for guest }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    describe "GET /groups/:path/merge_requests" do
      subject { merge_requests_group_path(group) }

      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_allowed_for master }
      it { is_expected.to be_allowed_for reporter }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for guest }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    describe "GET /groups/:path/members" do
      subject { members_group_path(group) }

      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_allowed_for master }
      it { is_expected.to be_allowed_for reporter }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for guest }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    describe "GET /groups/:path/edit" do
      subject { edit_group_path(group) }

      it { is_expected.to be_allowed_for owner }
      it { is_expected.to be_denied_for master }
      it { is_expected.to be_denied_for reporter }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_denied_for guest }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :visitor }
    end
  end
end
