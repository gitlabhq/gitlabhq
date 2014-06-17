require 'spec_helper'

describe "Group access", feature: true  do
  describe "GET /projects/new" do
    it { new_group_path.should be_allowed_for :admin }
    it { new_group_path.should be_allowed_for :user }
    it { new_group_path.should be_denied_for :visitor }
  end

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
    end

    describe "GET /groups/:path" do
      subject { group_path(group) }

      it { should be_allowed_for owner }
      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_allowed_for :admin }
      it { should be_allowed_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /groups/:path/issues" do
      subject { issues_group_path(group) }

      it { should be_allowed_for owner }
      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_allowed_for :admin }
      it { should be_allowed_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /groups/:path/merge_requests" do
      subject { merge_requests_group_path(group) }

      it { should be_allowed_for owner }
      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_allowed_for :admin }
      it { should be_allowed_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /groups/:path/members" do
      subject { members_group_path(group) }

      it { should be_allowed_for owner }
      it { should be_allowed_for master }
      it { should be_allowed_for reporter }
      it { should be_allowed_for :admin }
      it { should be_allowed_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /groups/:path/edit" do
      subject { edit_group_path(group) }

      it { should be_allowed_for owner }
      it { should be_denied_for master }
      it { should be_denied_for reporter }
      it { should be_allowed_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end

    describe "GET /groups/:path/projects" do
      subject { projects_group_path(group) }

      it { should be_allowed_for owner }
      it { should be_denied_for master }
      it { should be_denied_for reporter }
      it { should be_allowed_for :admin }
      it { should be_denied_for guest }
      it { should be_denied_for :user }
      it { should be_denied_for :visitor }
    end
  end
end
