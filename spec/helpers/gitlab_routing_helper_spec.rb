require 'spec_helper'

describe GitlabRoutingHelper do
  describe 'Project URL helpers' do
    describe '#project_member_path' do
      let(:project_member) { create(:project_member) }

      it { expect(project_member_path(project_member)).to eq project_project_member_path(project_member.source, project_member) }
    end

    describe '#request_access_project_members_path' do
      let(:project) { build_stubbed(:empty_project) }

      it { expect(request_access_project_members_path(project)).to eq request_access_project_project_members_path(project) }
    end

    describe '#leave_project_members_path' do
      let(:project) { build_stubbed(:empty_project) }

      it { expect(leave_project_members_path(project)).to eq leave_project_project_members_path(project) }
    end

    describe '#approve_access_request_project_member_path' do
      let(:project_member) { create(:project_member) }

      it { expect(approve_access_request_project_member_path(project_member)).to eq approve_access_request_project_project_member_path(project_member.source, project_member) }
    end

    describe '#resend_invite_project_member_path' do
      let(:project_member) { create(:project_member) }

      it { expect(resend_invite_project_member_path(project_member)).to eq resend_invite_project_project_member_path(project_member.source, project_member) }
    end
  end

  describe 'Group URL helpers' do
    describe '#group_members_url' do
      let(:group) { build_stubbed(:group) }

      it { expect(group_members_url(group)).to eq group_group_members_url(group) }
    end

    describe '#group_member_path' do
      let(:group_member) { create(:group_member) }

      it { expect(group_member_path(group_member)).to eq group_group_member_path(group_member.source, group_member) }
    end

    describe '#request_access_group_members_path' do
      let(:group) { build_stubbed(:group) }

      it { expect(request_access_group_members_path(group)).to eq request_access_group_group_members_path(group) }
    end

    describe '#leave_group_members_path' do
      let(:group) { build_stubbed(:group) }

      it { expect(leave_group_members_path(group)).to eq leave_group_group_members_path(group) }
    end

    describe '#approve_access_request_group_member_path' do
      let(:group_member) { create(:group_member) }

      it { expect(approve_access_request_group_member_path(group_member)).to eq approve_access_request_group_group_member_path(group_member.source, group_member) }
    end

    describe '#resend_invite_group_member_path' do
      let(:group_member) { create(:group_member) }

      it { expect(resend_invite_group_member_path(group_member)).to eq resend_invite_group_group_member_path(group_member.source, group_member) }
    end
  end
end
