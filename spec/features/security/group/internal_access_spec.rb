require 'rails_helper'

describe 'Internal group access', feature: true do
  include AccessMatchers
  include GroupAccessHelper



  describe 'GET /groups/:path' do
    subject { group_path(group(Gitlab::VisibilityLevel::INTERNAL)) }

    context "when user not in group project" do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to_not be_allowed_for :visitor }
    end

    context "when user in group project" do
      it { is_expected.to be_allowed_for project_group_member(:user) }
      it { is_expected.to_not be_allowed_for :visitor }
    end
  end

  describe 'GET /groups/:path/issues' do
    subject { issues_group_path(group(Gitlab::VisibilityLevel::INTERNAL)) }

    context "when user not in group project" do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to_not be_allowed_for :visitor }
    end

    context "when user in group project" do
      it { is_expected.to be_allowed_for project_group_member(:user) }
      it { is_expected.to_not be_allowed_for :visitor }
    end
  end

  describe 'GET /groups/:path/merge_requests' do
    subject { issues_group_path(group(Gitlab::VisibilityLevel::INTERNAL)) }

    context "when user not in group project" do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to_not be_allowed_for :visitor }
    end

    context "when user in group project" do
      it { is_expected.to be_allowed_for project_group_member(:user) }
      it { is_expected.to_not be_allowed_for :visitor }
    end
  end


  describe 'GET /groups/:path/group_members' do
    subject { issues_group_path(group(Gitlab::VisibilityLevel::INTERNAL)) }

    context "when user not in group project" do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to_not be_allowed_for :visitor }
    end

    context "when user in group project" do
      it { is_expected.to be_allowed_for project_group_member(:user) }
      it { is_expected.to_not be_allowed_for :visitor }
    end
  end

  describe 'GET /groups/:path/edit' do
    subject { issues_group_path(group(Gitlab::VisibilityLevel::INTERNAL)) }

    context "when user not in group project" do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to_not be_allowed_for :visitor }
    end

    context "when user in group project" do
      it { is_expected.to be_allowed_for project_group_member(:user) }
      it { is_expected.to_not be_allowed_for :visitor }
    end
  end
end
