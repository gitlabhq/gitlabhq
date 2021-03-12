# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Private Group access' do
  include AccessMatchers

  let(:group)   { create(:group, :private) }
  let(:project) { create(:project, :private, group: group) }
  let(:project_guest) do
    create(:user) do |user|
      project.add_guest(user)
    end
  end

  describe "Group should be private" do
    describe '#private?' do
      subject { group.private? }

      it { is_expected.to be_truthy }
    end
  end

  describe 'GET /groups/:path' do
    subject { group_path(group) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for(:admin) }
    end
    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for(:admin) }
    end
    it { is_expected.to be_allowed_for(:owner).of(group) }
    it { is_expected.to be_allowed_for(:maintainer).of(group) }
    it { is_expected.to be_allowed_for(:developer).of(group) }
    it { is_expected.to be_allowed_for(:reporter).of(group) }
    it { is_expected.to be_allowed_for(:guest).of(group) }
    it { is_expected.to be_allowed_for(project_guest) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe 'GET /groups/:path/-/issues' do
    subject { issues_group_path(group) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for(:admin) }
    end
    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for(:admin) }
    end
    it { is_expected.to be_allowed_for(:owner).of(group) }
    it { is_expected.to be_allowed_for(:maintainer).of(group) }
    it { is_expected.to be_allowed_for(:developer).of(group) }
    it { is_expected.to be_allowed_for(:reporter).of(group) }
    it { is_expected.to be_allowed_for(:guest).of(group) }
    it { is_expected.to be_allowed_for(project_guest) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe 'GET /groups/:path/-/merge_requests' do
    let(:project) { create(:project, :private, :repository, group: group) }

    subject { merge_requests_group_path(group) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for(:admin) }
    end
    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for(:admin) }
    end
    it { is_expected.to be_allowed_for(:owner).of(group) }
    it { is_expected.to be_allowed_for(:maintainer).of(group) }
    it { is_expected.to be_allowed_for(:developer).of(group) }
    it { is_expected.to be_allowed_for(:reporter).of(group) }
    it { is_expected.to be_allowed_for(:guest).of(group) }
    it { is_expected.to be_allowed_for(project_guest) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe 'GET /groups/:path/-/group_members' do
    subject { group_group_members_path(group) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for(:admin) }
    end
    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for(:admin) }
    end
    it { is_expected.to be_allowed_for(:owner).of(group) }
    it { is_expected.to be_allowed_for(:maintainer).of(group) }
    it { is_expected.to be_allowed_for(:developer).of(group) }
    it { is_expected.to be_allowed_for(:reporter).of(group) }
    it { is_expected.to be_allowed_for(:guest).of(group) }
    it { is_expected.to be_allowed_for(project_guest) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe 'GET /groups/:path/-/edit' do
    subject { edit_group_path(group) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for(:admin) }
    end
    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for(:admin) }
    end
    it { is_expected.to be_allowed_for(:owner).of(group) }
    it { is_expected.to be_denied_for(:maintainer).of(group) }
    it { is_expected.to be_denied_for(:developer).of(group) }
    it { is_expected.to be_denied_for(:reporter).of(group) }
    it { is_expected.to be_denied_for(:guest).of(group) }
    it { is_expected.to be_denied_for(project_guest) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:visitor) }
    it { is_expected.to be_denied_for(:external) }
  end

  describe 'GET /groups/:path for shared projects' do
    let(:project) { create(:project, :public) }

    before do
      create(:project_group_link, project: project, group: group)
    end

    subject { group_path(group) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed_for(:admin) }
    end
    context 'when admin mode is disabled' do
      it { is_expected.to be_denied_for(:admin) }
    end
    it { is_expected.to be_allowed_for(:owner).of(group) }
    it { is_expected.to be_allowed_for(:maintainer).of(group) }
    it { is_expected.to be_allowed_for(:developer).of(group) }
    it { is_expected.to be_allowed_for(:reporter).of(group) }
    it { is_expected.to be_allowed_for(:guest).of(group) }
    it { is_expected.to be_denied_for(project_guest) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end
end
