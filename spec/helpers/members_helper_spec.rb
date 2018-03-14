require 'spec_helper'

describe MembersHelper do
  describe '#remove_member_message' do
    let(:requester) { create(:user) }
    let(:project) { create(:project, :public, :access_requestable) }
    let(:project_member) { build(:project_member, project: project) }
    let(:project_member_invite) { build(:project_member, project: project).tap { |m| m.generate_invite_token! } }
    let(:project_member_request) { project.request_access(requester) }
    let(:group) { create(:group, :access_requestable) }
    let(:group_member) { build(:group_member, group: group) }
    let(:group_member_invite) { build(:group_member, group: group).tap { |m| m.generate_invite_token! } }
    let(:group_member_request) { group.request_access(requester) }

    it { expect(remove_member_message(project_member)).to eq "Are you sure you want to remove #{project_member.user.name} from the #{project.full_name} project?" }
    it { expect(remove_member_message(project_member_invite)).to eq "Are you sure you want to revoke the invitation for #{project_member_invite.invite_email} to join the #{project.full_name} project?" }
    it { expect(remove_member_message(project_member_request)).to eq "Are you sure you want to deny #{requester.name}'s request to join the #{project.full_name} project?" }
    it { expect(remove_member_message(project_member_request, user: requester)).to eq "Are you sure you want to withdraw your access request for the #{project.full_name} project?" }
    it { expect(remove_member_message(group_member)).to eq "Are you sure you want to remove #{group_member.user.name} from the #{group.name} group?" }
    it { expect(remove_member_message(group_member_invite)).to eq "Are you sure you want to revoke the invitation for #{group_member_invite.invite_email} to join the #{group.name} group?" }
    it { expect(remove_member_message(group_member_request)).to eq "Are you sure you want to deny #{requester.name}'s request to join the #{group.name} group?" }
    it { expect(remove_member_message(group_member_request, user: requester)).to eq "Are you sure you want to withdraw your access request for the #{group.name} group?" }
  end

  describe '#remove_member_title' do
    let(:requester) { create(:user) }
    let(:project) { create(:project, :public, :access_requestable) }
    let(:project_member) { build(:project_member, project: project) }
    let(:project_member_request) { project.request_access(requester) }
    let(:group) { create(:group, :access_requestable) }
    let(:group_member) { build(:group_member, group: group) }
    let(:group_member_request) { group.request_access(requester) }

    it { expect(remove_member_title(project_member)).to eq 'Remove user from project' }
    it { expect(remove_member_title(project_member_request)).to eq 'Deny access request from project' }
    it { expect(remove_member_title(group_member)).to eq 'Remove user from group' }
    it { expect(remove_member_title(group_member_request)).to eq 'Deny access request from group' }
  end

  describe '#leave_confirmation_message' do
    let(:project) { build_stubbed(:project) }
    let(:group) { build_stubbed(:group) }
    let(:user) { build_stubbed(:user) }

    it { expect(leave_confirmation_message(project)).to eq "Are you sure you want to leave the \"#{project.full_name}\" project?" }
    it { expect(leave_confirmation_message(group)).to eq "Are you sure you want to leave the \"#{group.name}\" group?" }
  end
end
