require 'spec_helper'

describe MembersHelper do
  describe '#member_class' do
    let(:project_member) { build(:project_member) }
    let(:group_member) { build(:group_member) }

    it { expect(member_class(project_member)).to eq ProjectMember }
    it { expect(member_class(group_member)).to eq GroupMember }
  end

  describe '#members_association' do
    let(:project) { build_stubbed(:project) }
    let(:group) { build_stubbed(:group) }

    it { expect(members_association(project)).to eq :project_members }
    it { expect(members_association(group)).to eq :group_members }
  end

  describe '#action_member_permission' do
    let(:project_member) { build(:project_member) }
    let(:group_member) { build(:group_member) }

    it { expect(action_member_permission(:admin, project_member)).to eq :admin_project_member }
    it { expect(action_member_permission(:admin, group_member)).to eq :admin_group_member }
  end

  describe '#can_see_entity_roles?' do
    let(:project) { create(:project) }
    let(:group) { create(:group) }
    let(:user) { build(:user) }
    let(:admin) { build(:user, :admin) }
    let(:project_member) { create(:project_member, project: project) }
    let(:group_member) { create(:group_member, group: group) }

    it { expect(can_see_entity_roles?(nil, project)).to be_falsy }
    it { expect(can_see_entity_roles?(nil, group)).to be_falsy }
    it { expect(can_see_entity_roles?(admin, project)).to be_truthy }
    it { expect(can_see_entity_roles?(admin, group)).to be_truthy }
    it { expect(can_see_entity_roles?(project_member.user, project)).to be_truthy }
    it { expect(can_see_entity_roles?(group_member.user, group)).to be_truthy }
  end

  describe '#member_path' do
    let(:project_member) { create(:project_member) }
    let(:group_member) { create(:group_member) }

    it { expect(member_path(project_member)).to eq namespace_project_project_member_path(project_member.source.namespace, project_member.source, project_member) }
    it { expect(member_path(group_member)).to eq group_group_member_path(group_member.source, group_member) }
    it { expect { member_path(double(:member, source: 'foo')) }.to raise_error ArgumentError, 'Unknown object class' }
  end

  describe '#resend_invite_member_path' do
    let(:project_member) { create(:project_member) }
    let(:group_member) { create(:group_member) }

    it { expect(resend_invite_member_path(project_member)).to eq resend_invite_namespace_project_project_member_path(project_member.source.namespace, project_member.source, project_member) }
    it { expect(resend_invite_member_path(group_member)).to eq resend_invite_group_group_member_path(group_member.source, group_member) }
    it { expect { resend_invite_member_path(double(:member, source: 'foo')) }.to raise_error ArgumentError, 'Unknown object class' }
  end

  describe '#request_access_path' do
    let(:project) { build_stubbed(:project) }
    let(:group) { build_stubbed(:group) }

    it { expect(request_access_path(project)).to eq request_access_namespace_project_project_members_path(project.namespace, project) }
    it { expect(request_access_path(group)).to eq request_access_group_group_members_path(group) }
    it { expect { request_access_path(double(:member, source: 'foo')) }.to raise_error ArgumentError, 'Unknown object class' }
  end

  describe '#approve_request_member_path' do
    let(:project_member) { create(:project_member) }
    let(:group_member) { create(:group_member) }

    it { expect(approve_request_member_path(project_member)).to eq approve_namespace_project_project_member_path(project_member.source.namespace, project_member.source, project_member) }
    it { expect(approve_request_member_path(group_member)).to eq approve_group_group_member_path(group_member.source, group_member) }
    it { expect { approve_request_member_path(double(:member, source: 'foo')) }.to raise_error ArgumentError, 'Unknown object class' }
  end

  describe '#leave_path' do
    let(:project) { build_stubbed(:project) }
    let(:group) { build_stubbed(:group) }

    it { expect(leave_path(project)).to eq leave_namespace_project_project_members_path(project.namespace, project) }
    it { expect(leave_path(group)).to eq leave_group_group_members_path(group) }
    it { expect { leave_path(double(:member, source: 'foo')) }.to raise_error ArgumentError, 'Unknown object class' }
  end

  describe '#withdraw_request_message' do
    let(:project) { build_stubbed(:project) }
    let(:group) { build_stubbed(:group) }

    it { expect(withdraw_request_message(project)).to eq "Are you sure you want to withdraw your access request for the \"#{project.name_with_namespace}\" project?" }
    it { expect(withdraw_request_message(group)).to eq "Are you sure you want to withdraw your access request for the \"#{group.name}\" group?" }
  end

  describe '#remove_member_message' do
    let(:requester) { build(:user) }
    let(:project) { create(:project) }
    let(:project_member) { build(:project_member, project: project) }
    let(:project_member_invite) { build(:project_member, project: project).tap { |m| m.generate_invite_token! } }
    let(:project_member_request) { project.request_access(requester) }
    let(:group) { create(:group) }
    let(:group_member) { build(:group_member, group: group) }
    let(:group_member_invite) { build(:group_member, group: group).tap { |m| m.generate_invite_token! } }
    let(:group_member_request) { group.request_access(requester) }

    it { expect(remove_member_message(project_member)).to eq "You are going to remove #{project_member.user.name} from the #{project.name_with_namespace} project. Are you sure?" }
    it { expect(remove_member_message(project_member_invite)).to eq "You are going to revoke the invitation for #{project_member_invite.invite_email} to join the #{project.name_with_namespace} project. Are you sure?" }
    it { expect(remove_member_message(project_member_request)).to eq "You are going to deny #{requester.name}'s request to join the #{project.name_with_namespace} project. Are you sure?" }
    it { expect(remove_member_message(group_member)).to eq "You are going to remove #{group_member.user.name} from the #{group.name} group. Are you sure?" }
    it { expect(remove_member_message(group_member_invite)).to eq "You are going to revoke the invitation for #{group_member_invite.invite_email} to join the #{group.name} group. Are you sure?" }
    it { expect(remove_member_message(group_member_request)).to eq "You are going to deny #{requester.name}'s request to join the #{group.name} group. Are you sure?" }
  end

  describe '#remove_member_title' do
    let(:requester) { build(:user) }
    let(:project) { create(:project) }
    let(:project_member) { build(:project_member, project: project) }
    let(:project_member_request) { project.request_access(requester) }
    let(:group) { create(:group) }
    let(:group_member) { build(:group_member, group: group) }
    let(:group_member_request) { group.request_access(requester) }

    it { expect(remove_member_title(project_member)).to eq 'Remove user' }
    it { expect(remove_member_title(project_member_request)).to eq 'Deny access request' }
    it { expect(remove_member_title(group_member)).to eq 'Remove user' }
    it { expect(remove_member_title(group_member_request)).to eq 'Deny access request' }
  end

  describe '#leave_confirmation_message' do
    let(:project) { build_stubbed(:project) }
    let(:group) { build_stubbed(:group) }
    let(:user) { build_stubbed(:user) }

    it { expect(leave_confirmation_message(project)).to eq "Are you sure you want to leave \"#{project.name_with_namespace}\" project?" }
    it { expect(leave_confirmation_message(group)).to eq "Are you sure you want to leave \"#{group.name}\" group?" }
  end
end
