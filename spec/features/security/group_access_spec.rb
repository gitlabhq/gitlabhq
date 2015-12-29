require 'rails_helper'

describe 'Group access', feature: true do
  include AccessMatchers

  def group
    @group ||= create(:group)
  end

  def create_project(access_level)
    if access_level == :mixed
      create(:empty_project, :public, group: group)
      create(:empty_project, :internal, group: group)
    else
      create(:empty_project, access_level, group: group)
    end
  end

  def group_member(access_level, grp = group())
    level = Object.const_get("Gitlab::Access::#{access_level.upcase}")

    create(:user).tap do |user|
      grp.add_user(user, level)
    end
  end

  describe 'GET /groups/new' do
    subject { new_group_path }

    it { is_expected.to be_allowed_for :admin }
    it { is_expected.to be_allowed_for :user }
    it { is_expected.to be_denied_for :visitor }
  end

  describe 'GET /groups/:path' do
    subject { group_path(group) }

    context 'with public projects' do
      let!(:project) { create_project(:public) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with mixed projects' do
      let!(:project) { create_project(:mixed) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with internal projects' do
      let!(:project) { create_project(:internal) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with no projects' do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end
  end

  describe 'GET /groups/:path/issues' do
    subject { issues_group_path(group) }

    context 'with public projects' do
      let!(:project) { create_project(:public) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with mixed projects' do
      let!(:project) { create_project(:mixed) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with internal projects' do
      let!(:project) { create_project(:internal) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    context 'with no projects' do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :visitor }
    end
  end

  describe 'GET /groups/:path/merge_requests' do
    subject { merge_requests_group_path(group) }

    context 'with public projects' do
      let!(:project) { create_project(:public) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with mixed projects' do
      let!(:project) { create_project(:mixed) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with internal projects' do
      let!(:project) { create_project(:internal) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    context 'with no projects' do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :visitor }
    end
  end

  describe 'GET /groups/:path/group_members' do
    subject { group_group_members_path(group) }

    context 'with public projects' do
      let!(:project) { create_project(:public) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with mixed projects' do
      let!(:project) { create_project(:mixed) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_allowed_for :visitor }
    end

    context 'with internal projects' do
      let!(:project) { create_project(:internal) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_allowed_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    context 'with no projects' do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_allowed_for group_member(:master) }
      it { is_expected.to be_allowed_for group_member(:reporter) }
      it { is_expected.to be_allowed_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :visitor }
    end
  end

  describe 'GET /groups/:path/edit' do
    subject { edit_group_path(group) }

    context 'with public projects' do
      let!(:project) { create_project(:public) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_denied_for group_member(:master) }
      it { is_expected.to be_denied_for group_member(:reporter) }
      it { is_expected.to be_denied_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    context 'with mixed projects' do
      let!(:project) { create_project(:mixed) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_denied_for group_member(:master) }
      it { is_expected.to be_denied_for group_member(:reporter) }
      it { is_expected.to be_denied_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    context 'with internal projects' do
      let!(:project) { create_project(:internal) }

      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_denied_for group_member(:master) }
      it { is_expected.to be_denied_for group_member(:reporter) }
      it { is_expected.to be_denied_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :visitor }
    end

    context 'with no projects' do
      it { is_expected.to be_allowed_for group_member(:owner) }
      it { is_expected.to be_denied_for group_member(:master) }
      it { is_expected.to be_denied_for group_member(:reporter) }
      it { is_expected.to be_denied_for group_member(:guest) }
      it { is_expected.to be_allowed_for :admin }
      it { is_expected.to be_denied_for :user }
      it { is_expected.to be_denied_for :visitor }
    end
  end
end
